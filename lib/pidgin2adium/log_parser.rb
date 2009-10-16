# Contains the class BasicParser and its subclasses, HtmlLogParser and
# TextFileParser, which parse the file passed into it and return a LogFile
# object. 
#
# Please use Pidgin2Adium.parse or Pidgin2Adium.parse_and_generate instead of
# using these classes directly.
require 'parsedate'

require 'pidgin2adium/balance_tags'
require 'pidgin2adium/log_file'

module Pidgin2Adium
    # Empty class. Raise'd by LogParser if the first line of a log is not
    # parseable.
    class InvalidFirstLineError < StandardError; end

    # BasicParser is a base class. Its subclasses are TextLogParser and
    # HtmlLogParser.
    #
    # Please use Pidgin2Adium.parse or Pidgin2Adium.parse_and_generate instead of
    # using this class directly.
    class BasicParser
	include Pidgin2Adium
	def initialize(src_path, user_aliases)
	    @src_path = src_path
	    # Whitespace is removed for easy matching later on.
	    @user_aliases = user_aliases.split(',').map!{|x| x.downcase.gsub(/\s+/,'') }.uniq
	    # @user_alias is set each time get_sender_by_alias is called. It is a non-normalized
	    # alias.
	    # Set an initial value just in case the first message doesn't give
	    # us an alias.
	    @user_alias = user_aliases.split(',')[0]

	    @tz_offset = get_time_zone_offset()
	   
	    file = File.new(@src_path, 'r')
	    @first_line = file.readline
	    @file_content = file.read
	    file.close

	    # Time regexes must be set before pre_parse().
	    # "4/18/2007 11:02:00 AM" => %w{4, 18, 2007, 11, 02, 00, AM}
	    # ONLY used (if at all) in first line of chat ("Conversation with...at...")
	    @time_regex_first_line = %r{(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2}):(\d{2}) ([AP]M)}
	    # "2007-04-17 12:33:13" => %w{2007, 04, 17, 12, 33, 13}
	    @time_regex = /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/
	    # sometimes a line in a chat doesn't have a full timestamp
	    # "04:22:05 AM" => %w{04 22 05 AM}
	    @minimal_time_regex = /(\d{1,2}):(\d{2}):(\d{2})( [AP]M)?/

	    # Whether or not the first line is parseable.
	    @first_line_is_valid = true
	    begin
		@service,
		@user_SN,
		@partner_SN,
		# @basic_time_info is for files that only have the full
		# timestamp at the top; we can use it to fill in the minimal
		# per-line timestamps. It has only 3 elements (year, month,
		# dayofmonth) because you should be able to fill everything
		# else in. If you can't, something's wrong.
		@basic_time_info,
		# When the chat started, in Adium's format
		@adium_chat_time_start = pre_parse()
	    rescue InvalidFirstLineError
		@first_line_is_valid = false
		error("Parsing of #{@src_path} failed (could not find valid first line).")
		return # stop processing
	    end
	    
	    # @status_map, @lib_purple_events, and @events are used in
	    # create_status_or_event_msg
	    @status_map = {
		/(.+) logged in\.$/ => 'online',
		/(.+) logged out\.$/ => 'offline',
		/(.+) has signed on\.$/ => 'online',
		/(.+) has signed off\.$/ => 'offline',
		/(.+) has gone away\.$/ => 'away',
		/(.+) is no longer away\.$/ => 'available',
		/(.+) has become idle\.$/ => 'idle',
		/(.+) is no longer idle\.$/ => 'available'
	    }

	    # lib_purple_events are all of event_type libPurple
	    @lib_purple_events = [
		# file transfer
		/Starting transfer of .+ from (.+)/,
		/^Offering to send .+ to (.+)$/,
		/(.+) is offering to send file/,
		/^Transfer of file .+ complete$/,
		/Error reading|writing|accessing .+: .+/,
		/You cancelled the transfer of/,
		/File transfer cancelled/,
		/(.+) cancelled the transfer of/,
		/(.+) cancelled the file transfer/,
		# Direct IM - actual (dis)connect events are their own types
		/^Attempting to connect to (.+) at .+ for Direct IM\./,
		/^Asking (.+) to connect to us at .+ for Direct IM\./,
		/^Attempting to connect via proxy server\.$/,
		/^Direct IM with (.+) failed/,
		# encryption
		/Received message encrypted with wrong key/,
		/^Requesting key\.\.\.$/,
		/^Outgoing message lost\.$/,
		/^Conflicting Key Received!$/,
		/^Error in decryption- asking for resend\.\.\.$/,
		/^Making new key pair\.\.\.$/,
		# file transfer
		/You canceled the transfer of/,
		/(.+?) canceled the transfer of/, 
		# sending errors
		/^Last outgoing message not received properly- resetting$/,
		/Resending\.\.\./,
		# connection errors
		/Lost connection with the remote user:.+/,
		# chats
		/^.+ entered the room\.$/,
		/^.+ left the room\.$/
	    ]

	    # non-libpurple events
	    # Each key maps to an event_type string. The keys will be matched against a line of chat
	    # and the partner's alias will be in regex group 1, IF the alias is matched.
	    @event_map = {
		# .+ is not an alias, it's a proxy server so no grouping
		/^Attempting to connect to .+\.$/ => 'direct-im-connect',
		# NB: pidgin doesn't track when Direct IM is disconnected, AFAIK
		/^Direct IM established$/ => 'directIMConnected',
		/Unable to send message/ => 'chat-error',
		/You missed .+ messages from (.+) because they were too large/ => 'chat-error',
		/User information not available/ => 'chat-error'
	    }

	    @ignore_events = [
		# Adium ignores SN/alias changes. 
		/^.+? is now known as .+?\.<br\/?>$/
	    ]
	end

	# This method returns a LogFile instance, or false if an error occurred.
	def parse
	    return false unless @first_line_is_valid
	    @file_content = cleanup(@file_content).split("\n")

	    @file_content.map! do |line|
		next if line =~ /^\s+$/
		if line =~ @line_regex
		    create_msg($~.captures)
		elsif line =~ @line_regex_status
		    create_status_or_event_msg($~.captures)
		else
		    error "Could not parse line:"
		    p line # returns nil which is then removed by compact
		    exit 1 # if $DEBUG FIXME
		end
	    end.compact!
	    return LogFile.new(@file_content, @service, @user_SN, @partner_SN, @adium_chat_time_start)
	end

	#################
	private
	#################

	def get_time_zone_offset()
	    tz_match = /([-\+]\d+)[A-Z]{3}\.(?:txt|htm|html)/.match(@src_path)
	    tz_offset = tz_match[1] rescue ''
	    return tz_offset
	end

	#--
	# Adium time format: YYYY-MM-DD\THH.MM.SS[+-]TZ_HRS like:
	# 2008-10-05T22.26.20-0800
	#++
	# Converts a pidgin datestamp to an Adium one.
	def create_adium_time(time, is_first_line = false)
	    # parsed_date = [year, month, day, hour, min, sec]
	    if time =~ @time_regex
		year, month, day, hour, min, sec = $1.to_i,
						   $2.to_i,
						   $3.to_i,
						   $4.to_i,
						   $5.to_i,
						   $6.to_i
	    elsif is_first_line and time =~ @time_regex_first_line
		hour = $4.to_i
		if $7 == 'PM' and hour != 12
		    hour += 12
		end
		year, month, day, min, sec = $3.to_i, # year
					     $1.to_i, # month
					     $2.to_i, # day
						        # already did hour
					     $5.to_i, # minutes
					     $6.to_i  # seconds
	    elsif time =~ @minimal_time_regex
		# "04:22:05" => %w{04 22 05}
		hour = $1.to_i
		if $4 == 'PM' and hour != 12
		    hour += 12
		end
		year, month, day = @basic_time_info
		min = $2.to_i
		sec = $3.to_i
	    else
		error("You have found an odd timestamp. Please report it to the developer.")
		log_msg("The timestamp: #{time}")
		log_msg("Continuing...")
		year,month,day,hour,min,sec = ParseDate.parsedate(time)
	    end
	    return Time.local(year,month,day,hour,min,sec).strftime("%Y-%m-%dT%H.%M.%S#{@tz_offset}")
	end

	# Extract required data from the file. Run by parse.
	def pre_parse
	    # Deal with first line.
	    
	    # the first line is special. It tells us (in order of regex groups):
	    # 1) who we're talking to 
	    # 2) what time/date
	    # 3) what SN we used
	    # 4) what protocol (AIM, icq, jabber...)
	    first_line_match = /Conversation with (.+?) at (.+?) on (.+?) \((.+?)\)/.match(@first_line)
	    if first_line_match.nil?
		raise InvalidFirstLineError
	    else
		service = first_line_match[4]
		# @user_SN is normalized to avoid "AIM.name" and "AIM.na me" folders
		user_SN = first_line_match[3].downcase.tr(' ', '')
		partner_SN = first_line_match[1]
		pidgin_chat_time_start = first_line_match[2]
		basic_time_info = case @first_line
				  when @time_regex: [$1.to_i, $2.to_i, $3.to_i]
				  when @time_regex_first_line: [$3.to_i, $1.to_i, $2.to_i]
				  end
		adium_chat_time_start = create_adium_time(pidgin_chat_time_start, true)
		return [service,
			user_SN,
			partner_SN,
			basic_time_info,
			adium_chat_time_start]
	    end
	end

	def get_sender_by_alias(alias_name)
	    no_action = alias_name.sub(/^\*{3}/, '')
	    if @user_aliases.include? no_action.downcase.gsub(/\s+/, '')
		# Set the current alias being used of the ones in @user_aliases
		@user_alias = no_action
		return @user_SN
	    else
		return @partner_SN
	    end
	end

	#--
	# create_msg takes an array of captures from matching against
	# @line_regex and returns a Message object or one of its subclasses.
	# It can be used for TextLogParser and HtmlLogParser because both of
	# them return data in the same indexes in the matches array.
	#++
	def create_msg(matches)
	    msg = nil
	    # Either a regular message line or an auto-reply/away message.
	    time = create_adium_time(matches[0])
	    buddy_alias = matches[1]
	    sender = get_sender_by_alias(buddy_alias)
	    body = matches[3]
	    if matches[2] # auto-reply
		msg = AutoReplyMessage.new(sender, time, buddy_alias, body)
	    else
		# normal message
		msg = XMLMessage.new(sender, time, buddy_alias, body)
	    end
	    return msg
	end

	#--
	# create_status_or_event_msg takes an array of +MatchData+ captures from
	# matching against @line_regex_status and returns an Event or Status.
	#++
	def create_status_or_event_msg(matches)
	    # ["22:58:00", "BuddyName logged in."]
	    # 0: time
	    # 1: status message or event
	    msg = nil
	    time = create_adium_time(matches[0])
	    str = matches[1]
	    # Return nil, which will get compact'ed out
	    return nil if @ignore_events.detect{|regex| str =~ regex }

	    regex, status = @status_map.detect{|regex, status| str =~ regex}
	    if regex and status
		# Status message
		buddy_alias = regex.match(str)[1]
		sender = get_sender_by_alias(buddy_alias)
		msg = StatusMessage.new(sender, time, buddy_alias, status)
	    else
		# Test for event
		regex = @lib_purple_events.detect{|regex| str =~ regex }
		event_type = 'libpurpleEvent' if regex
		unless regex and event_type
		    # not a libpurple event, try others
		    if @event_map.detect{|regex,event_type| str =~ regex}
			regex, event_type = $1, $2
		    else
			error("Could not match string to status or event!")
			error(sprintf("matches: %p", matches))
			error(sprintf("str: %p", str))
			exit 1
		    end
		end
		if regex and event_type
		    regex_matches = regex.match(str)
		    # Event message
		    if regex_matches.size == 1
			# No alias - this means it's the user
			buddy_alias = @user_alias
			sender = @user_SN
		    else
			buddy_alias = regex_matches[1]
			sender = get_sender_by_alias(buddy_alias)
		    end
		    msg = Event.new(sender, time, buddy_alias, str, event_type)
		end
	    end
	    return msg
	end
    end

    # Please use Pidgin2Adium.parse or Pidgin2Adium.parse_and_generate instead of
    # using this class directly.
    class TextLogParser < BasicParser
	def initialize(src_path, user_aliases)
	    super(src_path, user_aliases)
	    @timestamp_rx = '\((\d{1,2}:\d{1,2}:\d{1,2})\)'
	    
	    # @line_regex matches a line in a TXT log file other than the first
	    # @line_regex matchdata:
	    # 0: timestamp
	    # 1: screen name or alias, if alias set
	    # 2: "<AUTO-REPLY>" or nil
	    # 3: message body
	    @line_regex = /#{@timestamp_rx} (.*?) ?(<AUTO-REPLY>)?: (.*)/o
	    # @line_regex_status matches a status line
	    # @line_regex_status matchdata:
	    # 0: timestamp
	    # 1: status message
	    @line_regex_status = /#{@timestamp_rx} ([^:]+)/o
	end

	#################
	private
	#################

	def cleanup(text)
	    text.tr!("\r", '')
	    # Replace newlines with "<br/>" unless they end a chat line.
	    text.gsub!(/\n(?!#{@timestamp_rx}|\Z)/, '<br/>')
	    # Escape entities since this will be in XML
	    text.gsub!('&', '&amp;') # escape '&' first
	    text.gsub!('<', '&lt;')
	    text.gsub!('>', '&gt;')
	    text.gsub!('"', '&quot;')
	    text.gsub!("'", '&apos;')
	    return text
	end
    end

    # Please use Pidgin2Adium.parse or Pidgin2Adium.parse_and_generate instead
    # of using this class directly.
    class HtmlLogParser < BasicParser
	def initialize(src_path, user_aliases) 
	    super(src_path, user_aliases)
	    @timestamp_rx = '\(((?:\d{4}-\d{2}-\d{2} )?\d{1,2}:\d{1,2}:\d{1,2}(?: [AP]M)?)\)'
	    
	    # @line_regex matches a line in an HTML log file other than the
	    # first time matches on either "2008-11-17 14:12" or "14:12"
	    # @line_regex match obj:
	    # 0: timestamp, extended or not
	    # 1: screen name or alias, if alias set
	    # 2: "&lt;AUTO-REPLY&gt;" or nil
	    # 3: message body
	    # The ":" is optional to allow for strings like "(17:12:21) <b>***Gabe B-W</b> is confused<br/>"
	    @line_regex = /#{@timestamp_rx} ?<b>(.+?) ?(&lt;AUTO-REPLY&gt;)?:?<\/b> ?(.+)<br ?\/>/o
	    # @line_regex_status matches a status line
	    # @line_regex_status match obj:
	    # 0: timestamp
	    # 1: status message
	    @line_regex_status = /#{@timestamp_rx} ?<b> (.+)<\/b><br ?\/>/o
	end

	#################
	private
	#################

	# Returns a cleaned string.
	# Removes the following tags from _text_:
	# * html
	# * body
	# * font
	# * a with no innertext, e.g. <a href="blah"></a>
	# And removes the following style declarations:
	# * color: #000000 (just turns text black)
	# * font-family
	# * font-size
	# * background
	# * em (really it's changed to <span style="font-style: italic;">)
	# Since each <span> has only one style declaration, spans with these
	# declarations are removed (but the text inside them is preserved).
	def cleanup(text)
	    # Sometimes this is in there. I don't know why.
	    text.gsub!(%r{&lt;/FONT HSPACE='\d'>}, '')
	    # We can remove <font> safely since Pidgin and Adium both show bold
	    # using <span style="font-weight: bold;"> except Pidgin uses single
	    # quotes while Adium uses double quotes.
	    text.gsub!(/<\/?(?:html|body|font)(?: .+?)>/, '')

	    text.tr!("\r", '')
	    # Remove empty lines
	    text.gsub!("\n\n", "\n")
	    
	    # Remove newlines that end the file, since they screw up the 
	    # newline -> <br/> conversion
	    text.gsub!(/\n\Z/, '')
	    
	    # Replace newlines with "<br/>" unless they end a chat line.
	    # This must go after we remove <font> tags.
	    text.gsub!(/\n(?!#{@timestamp_rx})/, '<br/>')
	    
	    # These empty links are sometimes appended to every line in a chat,
	    # for some weird reason. Remove them.
	    text.gsub!(%r{<a href=('").+?\1>\s*?</a>}, '')
	
	    # Replace single quotes inside tags with double quotes so we can
	    # easily change single quotes to entities.
	    # For spans, removes a space after the final declaration if it exists.
	    text.gsub!(/<span style='([^']+?;) ?'>/, '<span style="\1">')
	    text.gsub!(/([a-z]+=)'(.+?)'/, '\1"\2"')
=begin
	    text.gsub!(/<a href='(.+?)'>/, '<a href="\1">')
	    text.gsub!(/<img src='([^']+?)'/, '<img src="\1"')
	    text.gsub!(/ alt='([^']+?)'/, ' alt="\1"')
=end
	    text.gsub!("'", '&apos;')

	    # This actually does match stuff, but doesn't group it correctly. :(
	    # text.gsub!(%r{<span style="((?:.+?;)+)">(.*?)</span>}) do |s|
	    text.gsub!(%r{<span style="(.+?)">(.*?)</span>}) do |s|
		# Remove empty spans.
		next if $2 == ''

		# style = style declaration
		# innertext = text inside <span>
		style, innertext = $1, $2
		# TODO: replace double quotes with "&quot;", but only outside tags; may still be tags inside spans
		innertext.gsub!("")
		
		styleparts = style.split(/; ?/)
		styleparts.map! do |p|
		    if p =~ /^color/
			# Regarding the bit with the ">", sometimes this happens:
			# <span style="color: #000000>today;">today was busy</span>
			# Then p = "color: #000000>today"
			# Or it can end in ">;", with no text before the semicolon.
			# So remove the ">" and anything following it.
			
			# Use regex instead of string, to account for funky ">" stuff
			if p =~ /color: #000000/
			    next
			elsif p =~ /(color: #[0-9a-fA-F]{6})(>.*)?/
			    # Keep the color but remove the bit after it
			    next($1)
			end
		    else
			# don't remove font-weight
			case p
			when /^font-family/: next
			when /^font-size/: next
			when /^background/: next
			end
		    end
		end.compact!
		unless styleparts.empty?
		    style = styleparts.join('; ')
		    innertext = "<span style=\"#{style};\">#{innertext}</span>"
		end
		innertext
	    end
	    # Pidgin uses <em>, Adium uses <span>
	    if text.gsub!('<em>', '<span style="font-style: italic;">')
		text.gsub!('</em>', '</span>')
	    end
	    return text
	end
    end

    # A holding object for each line of the chat. It is subclassed as
    # appropriate (eg AutoReplyMessage). Each subclass (but not Message
    # itself) has its own to_s which prints out its information in a format
    # appropriate for putting in an Adium log file.
    # Subclasses: XMLMessage, AutoReplyMessage, StatusMessage, Event.
    class Message
	def initialize(sender, time, buddy_alias)
	    @sender = sender
	    @time = time
	    @buddy_alias = buddy_alias
	end
	attr_accessor :sender, :time, :buddy_alias
    end
   
    # Basic message with body text (as opposed to pure status messages, which
    # have no body).
    class XMLMessage < Message
	include Pidgin2Adium
	def initialize(sender, time, buddy_alias, body)
	    super(sender, time, buddy_alias)
	    @body = body
	    @styled_body = '<div><span style="font-family: Helvetica; font-size: 12pt;">%s</span></div>' % @body
	    normalize_body!()
	end
	attr_accessor :body

	def to_s
	    return sprintf('<message sender="%s" time="%s" alias="%s">%s</message>' << "\n",
			   @sender, @time, @buddy_alias, @styled_body)
	end

	#################
	private
	#################

	# Balances mismatched tags, normalizes body style, and fixes actions
	# so they are in Adium style (Pidgin uses "***Buddy waves at you", Adium uses
	# "*Buddy waves at you*").
	def normalize_body!
	    normalize_body_entities!()
	    # Fix mismatched tags. Yes, it's faster to do it per-message
	    # than all at once.
	    @body = balance_tags(@body)
	    if @buddy_alias[0,3] == '***'
		# "***<alias>" is what pidgin sets as the alias for a /me action
		@buddy_alias.slice!(0,3)
		@body = '*' << @body << '*'
	    end
	end

	# Escapes entities.
	def normalize_body_entities!
	    # Convert '&' to '&amp;' only if it's not followed by an entity.
	    @body.gsub!(/&(?!lt|gt|amp|quot|apos)/, '&amp;')
	end
    end

    # An auto reply message.
    class AutoReplyMessage < XMLMessage
	def to_s
	    return sprintf('<message sender="%s" time="%s" auto="true" alias="%s">%s</message>' << "\n",
			   @sender, @time, @buddy_alias, @styled_body)
	end
    end

    # A message saying e.g. "Blahblah has gone away."
    class StatusMessage < Message
	def initialize(sender, time, buddy_alias, status)
	    super(sender, time, buddy_alias) 
	    @status = status
	end
	attr_accessor :status

	def to_s
	    return sprintf('<status type="%s" sender="%s" time="%s" alias="%s"/>' << "\n", @status, @sender, @time, @buddy_alias)
	end
    end
  
    # Pidgin does not have Events, but Adium does. Pidgin mostly uses system
    # messages to display what Adium calls events. These include sending a file,
    # starting a Direct IM connection, or an error in chat.
    class Event < XMLMessage
	def initialize(sender, time, buddy_alias, body, event_type)
	    super(sender, time, buddy_alias, body)
	    @event_type = event_type
	end
	attr_accessor :event_type

	def to_s
	    return sprintf('<event type="%s" sender="%s" time="%s" alias="%s">%s</event>',
			   @event_type, @sender, @time, @buddy_alias, @styled_body)
	end
    end
end # end module
