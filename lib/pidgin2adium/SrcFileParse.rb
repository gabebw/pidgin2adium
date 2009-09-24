# =SrcFileParse
# The class +SrcFileParse+ has 2 subclasses, +SrcTxtFileParse+ and +SrcHtmlFileParse+
# It parses the file passed into it and extracts the following
# from each line in the chat: time, alias, and message and/or status.

require 'parsedate'

module Pidgin2Adium
    # The two subclasses of +SrcFileParse+,
    # +SrcTxtFileParse+ and +SrcHtmlFileParse+, only differ
    # in that they have their own @lineRegex, @lineRegexStatus,
    # and most importantly, createMsg and createStatusOrEventMsg, which take
    # the +MatchData+ objects from matching against @lineRegex or
    # @lineRegexStatus, respectively and return object instances.
    # +createMsg+ returns a +Message+ instance (or one of its subclasses).
    # +createStatusOrEventMsg+ returns a +Status+ or +Event+ instance.
    class SrcFileParse
	def initialize(srcPath, destDirBase, userAliases, userTZ, userTZOffset)
	    @srcPath = srcPath
	    # these two are to pass to chatFG in parseFile
	    @destDirBase = destDirBase
	    @userAliases = userAliases
	    @userTZ = userTZ
	    @userTZOffset = userTZOffset
	    @tzOffset = getTimeZoneOffset()

	    # Used in @lineRegex{,Status}. Only one group: the entire timestamp.
	    @timestampRegexStr = '\(((?:\d{4}-\d{2}-\d{2} )?\d{1,2}:\d{1,2}:\d{1,2}(?: .{1,2})?)\)'
	    # the first line is special: it tells us
	    # 1) who we're talking to 
	    # 2) what time/date
	    # 3) what SN we used
	    # 4) what protocol (AIM, icq, jabber...)
	    @firstLineRegex = /Conversation with (.+?) at (.+?) on (.+?) \((.+?)\)/

	    # Possible formats for timestamps:
	    # "2007-04-17 12:33:13" => %w{2007, 04, 17, 12, 33, 13}
	    @timeRegexOne = /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/
	    # "4/18/2007 11:02:00 AM" => %w{4, 18, 2007, 11, 02, 00, AM}
	    @timeRegexTwo = %r{(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2}):(\d{2}) ([AP]M)}
	    # sometimes a line in a chat doesn't have a full timestamp
	    # "04:22:05 AM" => %w{04 22 05 AM}
	    @minimalTimeRegex = /(\d{1,2}):(\d{2}):(\d{2}) ?([AP]M)?/
	    
	    # {user,partner}SN set in parseFile() after reading the first line
	    @userSN = nil
	    @partnerSN = nil
	    
	    # @basicTimeInfo is for files that only have the full timestamp at
	    # the top; we can use it to fill in the minimal per-line timestamps.
	    # It has only 3 elements (year, month, dayofmonth) because
	    # you should be able to fill everything else in.
	    # If you can't, something's wrong.
	    @basicTimeInfo = []

	    # @userAlias is set each time getSenderByAlias is called. Set an
	    # initial value just in case the first message doesn't give us an
	    # alias.
	    @userAlias = @userAliases[0]
	    
	    # @statusMap, @libPurpleEvents, and @events are used in
	    # createStatusOrEventMessage.
	    @statusMap = {
		/(.+) logged in\.$/ => 'online',
		/(.+) logged out\.$/ => 'offline',
		/(.+) has signed on\.$/ => 'online',
		/(.+) has signed off\.$/ => 'offline',
		/(.+) has gone away\.$/ => 'away',
		/(.+) is no longer away\.$/ => 'available',
		/(.+) has become idle\.$/ => 'idle',
		/(.+) is no longer idle\.$/ => 'available'
	    }

	    # libPurpleEvents are all of eventType libPurple
	    @libPurpleEvents = [
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
		# file transfer - these are in this (non-used) list because you can't get the alias out of matchData[1]
		/^You canceled the transfer of .+$/,
		# sending errors
		/^Last outgoing message not received properly- resetting$/,
		/'Resending\.\.\./,
		# connection errors
		/Lost connection with the remote user:.+/,
		# chats
		/^.+ entered the room\.$/,
		/^.+ left the room\.$/
	    ]

	    # non-libpurple events
	    # Each key maps to an eventType string. The keys will be matched against a line of chat
	    # and the partner's alias will be in regex group 1, IF the alias is matched.
	    @eventMap = {
		# .+ is not an alias, it's a proxy server so no grouping
		/^Attempting to connect to .+\.$/ => 'direct-im-connect',
		# NB: pidgin doesn't track when Direct IM is disconnected, AFAIK
		/^Direct IM established$/ => 'directIMConnected',
		/Unable to send message. The message is too large./ => 'chat-error',
		/You missed .+ messages from (.+) because they were too large./ => 'chat-error'
	    }
	end

	def getTimeZoneOffset()
	    tzMatch = /([-\+]\d+)[A-Z]{3}\.txt|html?/.match(@srcPath)
	    tzOffset = tzMatch[1] rescue @userTZOffset
	    return tzOffset
	end

	# Adium time format: YYYY-MM-DD\THH.MM.SS[+-]TZ_HRS like:
	# 2008-10-05T22.26.20-0800
	def createAdiumTime(time)
	    # parsedDate = [year, month, day, hour, min, sec]
	    parsedDate = case time
			 when @timeRegexOne
			     [$~[1].to_i, # year
			     $~[2].to_i,  # month
			     $~[3].to_i,  # day
			     $~[4].to_i,  # hour
			     $~[5].to_i,  # minute
			     $~[6].to_i]  # seconds
			 when @timeRegexTwo
			     hours = $~[4].to_i
			     if $~[7] == 'PM' and hours != 12
				 hours += 12
			     end
			     [$~[3].to_i, # year
			      $~[1].to_i, # month
			      $~[2].to_i, # day
			      hours,
			      $~[5].to_i, # minutes
			      $~[6].to_i] # seconds
			 when @minimalTimeRegex
			     # "04:22:05" => %w{04 22 05}
			     hours = $~[1].to_i
			     if $~[4] == 'PM' and hours != 12
				 hours += 12
			     end
			     @basicTimeInfo + # [year, month, day]
			     [hours,
			      $~[2].to_i, # minutes
			      $~[3].to_i] # seconds
			 else
			     Pidgin2Adium.logMsg("You have found an odd timestamp.", true)
			     Pidgin2Adium.logMsg("Please report it to the developer.")
			     Pidgin2Adium.logMsg("The timestamp: #{time}")
			     Pidgin2Adium.logMsg("Continuing...")

			     ParseDate.parsedate(time)
			 end
	    return Time.local(*parsedDate).strftime("%Y-%m-%dT%H.%M.%S#{@tzOffset}")
	end

	# parseFile slurps up @srcPath into one big string and runs
	# SrcHtmlFileParse.cleanup if it's an HTML file.
	# It then uses regexes to break up the string, uses create(Status)Msg
	# to turn the regex MatchData into data hashes, and feeds it to
	# ChatFileGenerator, which creates the XML data string.
	# This method returns a ChatFileGenerator object.
	def parseFile()
	    file = File.new(@srcPath, 'r')
	    # Deal with first line.
	    firstLine = file.readline()
	    firstLineMatch = @firstLineRegex.match(firstLine)
	    if firstLineMatch.nil?
		file.close()
		Pidgin2Adium.logMsg("Parsing of #{@srcPath} failed (could not find valid first line).", true)
		return false
	    else
		# one big string, without the first line
		if self.class == SrcHtmlFileParse
		    fileContent = self.cleanup(file.read())
		else
		    fileContent = file.read()
		end
		file.close()
	    end
	    
	    service = firstLineMatch[4]
	    # userSN is standardized to avoid "AIM.name" and "AIM.na me" folders
	    @userSN = firstLineMatch[3].downcase.gsub(' ', '')
	    @partnerSN = firstLineMatch[1]
	    pidginChatTimeStart = firstLineMatch[2]
	    @basicTimeInfo = case firstLine
			     when @timeRegexOne: [$1.to_i, $2.to_i, $3.to_i]
			     when @timeRegexTwo: [$3.to_i, $1.to_i, $2.to_i]
			     end
	    adiumChatTimeStart = createAdiumTime(pidginChatTimeStart)

	    chatFG = ChatFileGenerator.new(service,
					   @userSN,
					   @partnerSN,
					   adiumChatTimeStart,
					   @destDirBase)
	    fileContent.each_line do |line|
		case line
		when @lineRegex
		    chatFG.appendLine( createMsg($~.captures) )
		when @lineRegexStatus
		    chatFG.appendLine( createStatusOrEventMsg($~.captures) )
		end
	    end
	    return chatFG
	end

	def getSenderByAlias(aliasName)
	    if @userAliases.include? aliasName.downcase.sub(/^\*{3}/,'').gsub(/\s+/, '')
		# Set the current alias being used of the ones in @userAliases
		@userAlias = aliasName.sub(/^\*{3}/, '')
		return @userSN
	    else
		return @partnerSN
	    end
	end

	# createMsg takes an array of captures from matching against @lineRegex
	# and returns a Message object or one of its subclasses.
	# It can be used for SrcTxtFileParse and SrcHtmlFileParse because
	# both of them return data in the same indexes in the matches array.
	def createMsg(matches)
	    msg = nil
	    # Either a regular message line or an auto-reply/away message.
	    time = createAdiumTime(matches[0])
	    aliasStr = matches[1]
	    sender = getSenderByAlias(aliasStr)
	    body = matches[3]
	    if matches[2] # auto-reply
		msg = AutoReplyMessage.new(sender, time, aliasStr, body)
	    else
		# normal message
		msg = XMLMessage.new(sender, time, aliasStr, body)
	    end
	    return msg
	end

	# createStatusOrEventMsg takes an array of +MatchData+ captures from
	# matching against @lineRegexStatus and returns an Event or Status.
	def createStatusOrEventMsg(matches)
	    # ["22:58:00", "BuddyName logged in."]
	    # 0: time
	    # 1: status message or event
	    msg = nil
	    time = createAdiumTime(matches[0])
	    str = matches[1]
	    regex, status = @statusMap.detect{|regex, status| str =~ regex}
	    if regex and status
		# Status message
		aliasStr = regex.match(str)[1]
		sender = getSenderByAlias(aliasStr)
		msg = StatusMessage.new(sender, time, aliasStr, status)
	    else
		# Test for event
		regex = @libPurpleEvents.detect{|regex| str =~ regex }
		eventType = 'libpurpleEvent' if regex
		unless regex and eventType
		    # not a libpurple event, try others
		    regexAndEventType = @eventMap.detect{|regex,eventType| str =~ regex}
		    regex = regexAndEventType[0]
		    eventType = regexAndEventType[1]
		end
		if regex and eventType
		    regexMatches = regex.match(str)
		    # Event message
		    if regexMatches.size == 1
			# No alias - this means it's the user
			aliasStr = @userAlias
			sender = @userSN
		    else
			aliasStr = regex.match(str)[1]
			sender = getSenderByAlias(aliasStr)
		    end
		    msg = Event.new(sender, time, aliasStr, str, eventType)
		end
	    end
	    return msg
	end
    end

    class SrcTxtFileParse < SrcFileParse
	def initialize(srcPath, destDirBase, userAliases, userTZ, userTZOffset)
	    super(srcPath, destDirBase, userAliases, userTZ, userTZOffset)
	    # @lineRegex matches a line in a TXT log file other than the first
	    # @lineRegex matchdata:
	    # 0: timestamp
	    # 1: screen name or alias, if alias set
	    # 2: "<AUTO-REPLY>" or nil
	    # 3: message body
	    @lineRegex = /#{@timestampRegexStr} (.*?) ?(<AUTO-REPLY>)?: (.*)$/o
	    # @lineRegexStatus matches a status line
	    # @lineRegexStatus matchdata:
	    # 0: timestamp
	    # 1: status message
	    @lineRegexStatus = /#{@timestampRegexStr} ([^:]+?)[\r\n]{1,2}/o
	end

    end

    class SrcHtmlFileParse < SrcFileParse
	def initialize(srcPath, destDirBase, userAliases, userTZ, userTZOffset)
	    super(srcPath, destDirBase, userAliases, userTZ, userTZOffset)
	    # @lineRegex matches a line in an HTML log file other than the first
	    # time matches on either "2008-11-17 14:12" or "14:12"
	    # @lineRegex match obj:
	    # 0: timestamp, extended or not
	    # 1: screen name or alias, if alias set
	    # 2: "&lt;AUTO-REPLY&gt;" or nil
	    # 3: message body
	    #  <span style='color: #000000;'>test sms</span>
	    @lineRegex = /#{@timestampRegexStr} ?<b>(.*?) ?(&lt;AUTO-REPLY&gt;)?:?<\/b> ?(.*)<br ?\/>/o
	    # @lineRegexStatus matches a status line
	    # @lineRegexStatus match obj:
	    # 0: timestamp
	    # 1: status message
	    @lineRegexStatus = /#{@timestampRegexStr} ?<b> (.*?)<\/b><br ?\/>/o
	end

	# Removes <font> tags, empty <a>s, and spans with either no color
	# information or color information that just turns the text black.
	# Returns a string.
	def cleanup(text)
	    # Pidgin and Adium both show bold using
	    # <span style="font-weight: bold;"> except Pidgin uses single quotes
	    # and Adium uses double quotes
	    text.gsub!(/<\/?(html|body|font).*?>/, '')
	    # These empty links are sometimes appended to every line in a chat,
	    # for some weird reason. Remove them.
	    text.gsub!(%r{<a href='.+?'>\s*?</a>}, '')
	    text.gsub!(%r{(.*?)<span.+style='(.+?)'>(.*?)</span>(.*)}) do |s|
		# before = text before match
		# style = style declaration
		# innertext = text inside <span>
		# after = text after match
		before, style, innertext, after = *($~[1..4])
		# TODO: remove after from string then see what balanceTags does
		# Remove empty spans.
		nil if innertext == ''
		# Only allow some style declarations
		# We keep:
		# font-weight: bold
		# color (except #000000)
		# text-decoration: underline
		styleparts = style.split(/; ?/)
		styleparts.map! do |p|
		    # Short-circuit for common declaration
		    # Yes, sometimes there's a ">" before the ";".
		    if p == 'color: #000000;' or
			p == 'color: #000000>;'
			nil
		    else
			case p
			when /font-family/: nil
			when /font-size/: nil
			when /background/: nil
			end
		    end
		end
		styleparts.compact!
		if styleparts.empty?
		    style = ''
		elsif styleparts.size == 1
		    p styleparts
		    exit 1
		    style = styleparts[0] << ';'
		else
		    style = styleparts.join('; ') << ';'
		end
		if style != ''
		    innertext = "<span style=\"#{style}\">#{innertext}</span>"
		end
		before + innertext + after
	    end
	    # Pidgin uses <em>, Adium uses <span>
	    if text.gsub!('<em>', '<span style="italic">')
		text.gsub!('</em>', '</span>')
	    end
	    return text
	end
    end

    # A holding object for each line of the chat.
    # It is subclassed as appropriate (eg AutoReplyMessage).
    # All Messages have senders, times, and aliases.
    class Message
	def initialize(sender, time, aliasStr)
	    @sender = sender
	    @time = time
	    @aliasStr = aliasStr
	end
    end
   
    # Basic message with body text (as opposed to pure status messages, which
    # have no body).
    class XMLMessage < Message
	def initialize(sender, time, aliasStr, body)
	    super(sender, time, aliasStr)
	    @body = body
	    normalizeBody!()
	end

	def getOutput
	    return sprintf('<message sender="%s" time="%s" alias="%s">%s</message>' << "\n",
			   @sender, @time, @aliasStr, @body)
	end

	def normalizeBody!
	    normalizeBodyEntities!()
	    # Fix mismatched tags. Yes, it's faster to do it per-message
	    # than all at once.
	    @body = Pidgin2Adium.balanceTags(@body)
	    if @aliasStr[0,3] == '***'
		# "***<alias>" is what pidgin sets as the alias for a /me action
		@aliasStr.slice!(0,3)
		@body = '*' << @body << '*'
	    end
	    @body = '<div><span style="font-family: Helvetica; font-size: 12pt;">' <<
	    @body << 
	    '</span></div>'
	end

	def normalizeBodyEntities!
	    # Convert '&' to '&amp;' only if it's not followed by an entity.
	    @body.gsub!(/&(?!lt|gt|amp|quot|apos)/, '&amp;')
	    # replace single quotes with '&apos;' but only outside <span>s.
	    @body.gsub!(/(.*?)(<span.*?>.*?<\/span>)(.*?)/) do
		before, span, after = $1, ($2||''), $3||''
		before.gsub("'", '&aquot;') <<
		    span <<
		    after.gsub("'", '&aquot;')
	    end
	end
    end

    # An auto reply message, meaning it has a body.
    class AutoReplyMessage < XMLMessage
	def getOutput
	    return sprintf('<message sender="%s" time="%s" auto="true" alias="%s">%s</message>' << "\n", @sender, @time, @aliasStr, @body)
	end
    end

    # A message saying e.g. "Blahblah has gone away."
    class StatusMessage < Message
	def initialize(sender, time, aliasStr, status)
	    super(sender, time, aliasStr) 
	    @status = status
	end
	def getOutput
	    return sprintf('<status type="%s" sender="%s" time="%s" alias="%s"/>' << "\n", @status, @sender, @time, @aliasStr)
	end
    end
  
    # An <event> line of the chat
    class Event < XMLMessage
	def initialize(sender, time, aliasStr, body, type="libpurpleMessage")
	    super(sender, time, aliasStr, body)
	    @type = type
	end

	def getOutput
	    return sprintf('<event type="%s" sender="%s" time="%s" alias="%s">%s</event>', @type, @sender, @time, @aliasStr, @body)
	end
    end
end # end module
