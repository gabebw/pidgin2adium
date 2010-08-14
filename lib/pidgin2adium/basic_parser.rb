# Contains the BasicParser class.
# For its subclasses, see html_log_parser.rb and text_log_parser.rb.
# The subclasses parse the file passed into it and return a LogFile object.
# The BasicParser class just provides some common functionality.
#
# Please use Pidgin2Adium.parse or Pidgin2Adium.parse_and_generate instead of
# using these classes directly.

require 'date'
require 'time'

require 'pidgin2adium/log_file'
require 'pidgin2adium/messages/all'

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

      @log_file_is_valid = true
      begin
        file = File.new(@src_path, 'r')
        @first_line = file.readline
        @file_content = file.read
        file.close
      rescue Errno::ENOENT
        oops("#{@src_path} doesn't exist! Continuing...")
        @log_file_is_valid = false
        return nil
      end

      # Time regexes must be set before pre_parse().
      # "4/18/2007 11:02:00 AM" => %w{4, 18, 2007, 11, 02, 00, AM}
      # ONLY used (if at all) in first line of chat ("Conversation with...at...")
      @time_regex_first_line = %r{^(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2}):(\d{2}) ([AP]M)$}
      # "2007-04-17 12:33:13" => %w{2007, 04, 17, 12, 33, 13}
      @time_regex = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/

      begin
        @service,
          @user_SN,
          @partner_SN,
          # @basic_time_info is for files that only have the full
          # timestamp at the top; we can use it to fill in the minimal
          # per-line timestamps. It is a hash with 3 keys:
          # * :year
          # * :mon
          # * :mday (day of month)
          # You should be able to fill everything else in. If you can't,
          # something's wrong.
          @basic_time_info,
          # When the chat started, in Adium's format
          @adium_chat_time_start = pre_parse()
      rescue InvalidFirstLineError
        # The first line isn't parseable
        @log_file_is_valid = false
        error("Failed to parse, invalid first line: #{@src_path}")
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
        /You cancell?ed the transfer of/,
        /File transfer cancelled/,
        /(.+?) cancell?ed the transfer of/,
        /(.+?) cancelled the file transfer/,
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
      # Prevent parse from being called directly from BasicParser, since
      # it uses subclassing magic.
      if self.class == BasicParser
        oops("Please don't call parse directly from BasicParser. Use a subclass :)")
        return false
      end
      return false unless @log_file_is_valid
      @file_content = cleanup(@file_content).split("\n")

      @file_content.map! do |line|
        # "next" returns nil which is removed by compact
        next if line =~ /^\s+$/
        if line =~ @line_regex
          create_msg($~.captures)
        elsif line =~ @line_regex_status
          msg = create_status_or_event_msg($~.captures)
          # Error occurred while parsing
          return false if msg == false
        else
          error "Could not parse line:"
          p line
          return false
        end
      end
      @file_content.compact!
      return LogFile.new(@file_content, @service, @user_SN, @partner_SN, @adium_chat_time_start)
    end

    def get_time_zone_offset()
      # We must have a tz_offset or else the Adium Chat Log viewer
      # doesn't read the date correctly and then:
      # 1) the log has an empty start date column in the viewer
      # 2) The timestamps are all the same for the whole log
      tz_match = /([-\+]\d+)[A-Z]{3}\.(?:txt|htm|html)/.match(@src_path)
      if tz_match and tz_match[1]
        tz_offset = tz_match[1]
      else
        tz_offset = Pidgin2Adium::DEFAULT_TZ_OFFSET
      end
      return tz_offset
    end

    def try_to_parse_first_line_time(first_line_time)
      formats = [
        "%m/%d/%Y %I:%M:%S %P", # 01/22/2008 03:01:45 PM
        "%Y-%m-%d %H:%M:%S"     # 2008-01-22 23:08:24
      ]
      parsed = nil
      formats.each do |format|
        begin
          parsed = Time.strptime(first_line_time, format)
          break
        rescue ArgumentError
        end
      end
      parsed
    end

    def try_to_parse_time(time)
      formats = [
        "%Y/%m/%d %H:%M:%S", # 2008/01/22 04:01:45
        "%Y-%m-%d %H:%M:%S"  # 2008-01-22 04:01:45
      ]
      parsed = nil
      formats.each do |format|
        begin
          parsed = Time.strptime(time, format)
          break
        rescue ArgumentError
        end
      end
      parsed
    end

    def try_to_parse_minimal_time(minimal_time)
      # 04:01:45 AM
      minimal_format_with_ampm = "%I:%M:%S %P"
      # 23:01:45
      minimal_format_without_ampm = "%H:%M:%S"

      time_hash = nil

      # Use Date._strptime to allow filling in the blanks on minimal
      # timestamps
      if minimal_time =~ /[AP]M$/
        time_hash = Date._strptime(minimal_time, minimal_format_with_ampm)
      else
        time_hash = Date._strptime(minimal_time, minimal_format_without_ampm)
      end
      if time_hash.nil?
        # Date._strptime returns nil on failure
        return nil
      end
      # Fill in the blanks
      time_hash[:year] = @basic_time_info[:year]
      time_hash[:mon] = @basic_time_info[:mon]
      time_hash[:mday] = @basic_time_info[:mday]
      new_time = Time.local(time_hash[:year],
                            time_hash[:mon],
                            time_hash[:mday],
                            time_hash[:hour],
                            time_hash[:min],
                            time_hash[:sec])
      new_time
    end


    #--
    # Adium time format: YYYY-MM-DD\THH:MM:SS[+-]TZ_HRS like:
    # 2008-10-05T22:26:20-0800
    # HOWEVER:
    # If it's the first line, then return it like this (note periods):
    # 2008-10-05T22.26.20-0800
    # because it will be used in the filename.
    #++
    # Converts a pidgin datestamp to an Adium one.
    # Returns a string representation of _time_ or
    # nil if it couldn't parse the provided _time_.
    def create_adium_time(time, is_first_line = false)
      return nil if time.nil?
      if is_first_line
        new_time = try_to_parse_first_line_time(time)
      else
        new_time = try_to_parse_time(time)
        if new_time.nil?
          new_time = try_to_parse_minimal_time(time)
        end
      end

      return nil if new_time.nil?

      if is_first_line
        adium_time = new_time.strftime("%Y-%m-%dT%H.%M.%S#{@tz_offset}")
      else
        adium_time = new_time.strftime("%Y-%m-%dT%H:%M:%S#{@tz_offset}")
      end
      adium_time
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
        basic_time_info = case pidgin_chat_time_start
                          when @time_regex
                            {:year => $1.to_i,
                             :mon => $2.to_i,
                             :mday => $3.to_i}
                          when @time_regex_first_line
                            {:year => $3.to_i,
                             :mon => $1.to_i,
                             :mday => $2.to_i}
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
    # they return data in the same indexes in the matches array.
    #++
    def create_msg(matches)
      msg = nil
      # Either a regular message line or an auto-reply/away message.
      time = create_adium_time(matches[0])
      return nil if time.nil?
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
    # Returns nil if it's a message that should be ignored, or false if an
    # error occurred.
    #++
    def create_status_or_event_msg(matches)
      # ["22:58:00", "BuddyName logged in."]
      # 0: time
      # 1: status message or event
      msg = nil
      time = create_adium_time(matches[0])
      return nil if time.nil?
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
          regex, event_type = @event_map.detect{|regex,event_type| str =~ regex}
          unless regex and event_type
            error(sprintf("Error parsing status or event message, no status or event found: %p", str))
            return false
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
  end # END BasicParser class
end
