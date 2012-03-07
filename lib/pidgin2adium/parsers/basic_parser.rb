# Contains the BasicParser class.
# For its subclasses, see html_log_parser.rb and text_log_parser.rb.
# The subclasses parse the file passed into it and return a LogFile object.
# The BasicParser class just provides some common functionality.
#
# Please use Pidgin2Adium.parse or Pidgin2Adium.parse_and_generate instead of
# using these classes directly.

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
    # Time regexes must be set before pre_parse!().
    # "4/18/2007 11:02:00 AM" => %w{4, 18, 2007}
    # ONLY used (if at all) in first line of chat ("Conversation with...at...")
    TIME_REGEX_FIRST_LINE = %r{^(\d{1,2})/(\d{1,2})/(\d{4}) \d{1,2}:\d{2}:\d{2} [AP]M$}
    # "2007-04-17 12:33:13" => %w{2007, 04, 17}
    TIME_REGEX = /^(\d{4})-(\d{2})-(\d{2}) \d{2}:\d{2}:\d{2}$/

    #  force_conversion: Should we continue to convert after hitting an unparseable line?
    def initialize(src_path, user_aliases, force_conversion = false)
      @src_path = src_path
      # Whitespace is removed for easy matching later on.
      @user_aliases = user_aliases.split(',').map!{|x| x.downcase.gsub(/\s+/,'') }.uniq

      @force_conversion = force_conversion
      # @user_alias is set each time get_sender_by_alias is called. It is a non-normalized
      # alias.
      # Set an initial value just in case the first message doesn't give
      # us an alias.
      @user_alias = user_aliases.split(',')[0]

      @log_file_is_valid = read_source_file

      begin
        successfully_set_variables = pre_parse!
        if ! successfully_set_variables
          Pidgin2Adium.error("Failed to set some key variables: #{@src_path}")
          @log_file_is_valid = false
          return
        end
      rescue InvalidFirstLineError
        # The first line isn't parseable
        @log_file_is_valid = false
        Pidgin2Adium.error("Failed to parse, invalid first line: #{@src_path}")
        return # stop processing
      end
    end

    # This method returns a LogFile instance, or false if an error occurred.
    def parse
      # Prevent parse from being called directly from BasicParser, since
      # it uses subclassing magic.
      if self.class == BasicParser
        Pidgin2Adium.warn("Please don't call parse directly from BasicParser. Use a subclass :)")
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
          if msg == false
            if force_conversion?
              nil # will get compacted out
            else
              # Error occurred while parsing
              return false
            end
          end
        else
          error "Could not parse line:"
          p line
          return false
        end
      end
      @file_content.compact!
      return LogFile.new(@file_content, @service, @user_SN, @partner_SN, @adium_chat_time_start)
    end

    # Converts a pidgin datestamp to an Adium one.
    # Returns a string representation of _time_ or
    # nil if it couldn't parse the provided _time_.
    def create_adium_time(time)
      if time.nil?
        nil
      else
        time = time_parser.parse(time)
        if time.nil?
          Pidgin2Adium.warn("#{time} couldn't be parsed. Please open an issue on GitHub: https://github.com/gabebw/pidgin2adium/issues")
          nil
        else
          time.strftime('%Y-%m-%dT%H:%M:%S%Z')
        end
      end
    end

    # Extract required data from the file. Run by parse. Sets these
    # variables:
    # * @service
    # * @user_SN
    # * @partner_SN
    # * @basic_time_info
    # * @adium_chat_time_start
    # Returns true if none of these variables are false or nil.
    def pre_parse!
      metadata = Metadata.new(@first_line)
      if metadata.invalid?
        raise InvalidFirstLineError
      else
        @service = metadata.service
        @user_SN = metadata.sender_screen_name
        @partner_SN = metadata.receiver_screen_name
        pidgin_chat_time_start = metadata.time_string
        # @basic_time_info is for files that only have the full
        # timestamp at the top; we can use it to fill in the minimal
        # per-line timestamps. It is a hash with 3 keys:
        # * :year
        # * :mon
        # * :mday (day of month)
        # You should be able to fill everything else in. If you can't,
        # something's wrong.
        @basic_time_info = case pidgin_chat_time_start
                           when TIME_REGEX
                             {:year => $1.to_i,
                              :month => $2.to_i,
                              :day => $3.to_i}
                           when TIME_REGEX_FIRST_LINE
                             {:year => $3.to_i,
                              :month => $1.to_i,
                              :day => $2.to_i}
                           else
                             nil
                           end
        if @basic_time_info.nil?
          begin
            parsed_time = DateTime.parse(pidgin_chat_time_start)
            @basic_time_info = {:year => parsed_time.year,
                                :month => parsed_time.mon,
                                :day => parsed_time.mday}
          rescue ArgumentError
            # Couldn't parse the date
            Pidgin2Adium.warn("#{@src_path}: couldn't parse the date in the first line.")
            @basic_time_info = nil
          end
        end

        # Note: need @basic_time_info set for create_adium_time
        # When the chat started, in Adium's format
        @adium_chat_time_start = create_adium_time(pidgin_chat_time_start)

        first_line_variables = [@service,
                                @user_SN,
                                @partner_SN,
                                @basic_time_info,
                                @adium_chat_time_start]
        if first_line_variables.all?
          true
        else
          # Print an informative error message
          unset_variable_names = []
          unset_variable_names << 'service' if @service.nil?
          unset_variable_names << 'user_SN' if @user_SN.nil?
          unset_variable_names << 'partner_SN' if @partner_SN.nil?
          unset_variable_names << 'basic_time_info' if @basic_time_info.nil?
          unset_variable_names << 'adium_chat_time_start' if @adium_chat_time_start.nil?
          Pidgin2Adium.warn("Couldn't set these variables: #{unset_variable_names.join(', ')}")
          false
        end
      end
    end

    def get_sender_by_alias(alias_name)
      no_action = alias_name.sub(/^\*{3}/, '')
      if @user_aliases.include?(no_action.downcase.gsub(/\s+/, ''))
        # Set the current alias being used of the ones in @user_aliases
        @user_alias = no_action
        @user_SN
      else
        @partner_SN
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
      time = create_adium_time(matches[0])
      str = matches[1]

      if time.nil? || ignorable_event?(str)
        nil
      else
        create_status_message(str, time) || create_event_message(str, time)
      end
    end

    def time_parser
      @time_parser ||= TimeParser.new(@basic_time_info[:year], @basic_time_info[:month], @basic_time_info[:day])
    end

    protected

    # Should we continue to convert after hitting an unparseable line?
    def force_conversion?
      !! @force_conversion
    end

    def print_conversion_error
      if ! printed_conversion_error?
        Pidgin2Adium.error("#{@src_path} was converted with the following errors:")
        printed_conversion_error!
      end
    end

    def printed_conversion_error?
      @printed_conversion_error == true
    end

    def printed_conversion_error!
      @printed_conversion_error = true
    end

    def read_source_file
      begin
        open(@src_path) do |f|
          @first_line = f.readline
          @file_content = f.read
        end
      rescue Errno::ENOENT
        Pidgin2Adium.warn("#{@src_path} doesn't exist! Continuing...")
        @log_file_is_valid = false
        return nil
      end
    end

    def ignorable_event?(str)
      ignore_events.detect{|regex| str =~ regex }
    end

    def create_status_message(str, time)
      regex, status = status_map.detect{|rxp, stat| str =~ rxp}
      if regex && status
        buddy_alias = regex.match(str)[1]
        sender = get_sender_by_alias(buddy_alias)
        msg = StatusMessage.new(sender, time, buddy_alias, status)
      end
    end

    def create_event_message(string, time)
      message = create_lib_purple_event_message(string, time) || create_non_lib_purple_event_message(string, time)

      if message
        message
      else
        if force_conversion?
          print_conversion_error
        end

        indent = if force_conversion?
                   "\t"
                 else
                   ""
                 end

        Pidgin2Adium.error("#{indent}Error parsing status or event message, no status or event found: #{string.inspect}")
        false
      end
    end

    def status_map
      {
        /(.+) logged in\.$/ => 'online',
        /(.+) logged out\.$/ => 'offline',
        /(.+) has signed on\.$/ => 'online',
        /(.+) has signed off\.$/ => 'offline',
        /(.+) has gone away\.$/ => 'away',
        /(.+) is no longer away\.$/ => 'available',
        /(.+) has become idle\.$/ => 'idle',
        /(.+) is no longer idle\.$/ => 'available'
      }
    end

    def lib_purple_events
      # All of event_type libPurple.
      [
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
    end

    def event_map
      # Each key maps to an event_type string. The keys will be matched against
      # a line of chat and the partner's alias will be in regex group 1, IF the
      # alias is matched.
      {
        # .+ is not an alias, it's a proxy server so no grouping
        /^Attempting to connect to .+\.$/ => 'direct-im-connect',
        # NB: pidgin doesn't track when Direct IM is disconnected, AFAIK
        /^Direct IM established$/ => 'directIMConnected',
        /Unable to send message/ => 'chat-error',
        /You missed .+ messages from (.+) because they were too large/ => 'chat-error',
        /User information not available/ => 'chat-error'
      }
    end

    def ignore_events
      [
        # Adium ignores SN/alias changes.
        /^.+? is now known as .+?\.<br\/?>$/
      ]
    end

    def create_lib_purple_event_message(str, time)
      regex = lib_purple_events.detect{|rxp| str =~ rxp }
      if regex
        event_type = 'libpurpleEvent'
        create_event_message_from(regex, str, time, event_type)
      end
    end

    def create_non_lib_purple_event_message(string, time)
      regex, event_type = event_map.detect{|rxp,ev_type| string =~ rxp}
      if regex && event_type
        create_event_message_from(regex, string, time, event_type)
      end
    end

    def create_event_message_from(regex, string, time, event_type)
      regex_matches = regex.match(string)
      if regex_matches.size == 1
        # No alias - this means it's the user
        buddy_alias = @user_alias
        sender = @user_SN
      else
        buddy_alias = regex_matches[1]
        sender = get_sender_by_alias(buddy_alias)
      end
      msg = Event.new(sender, time, buddy_alias, string, event_type)
    end
  end
end
