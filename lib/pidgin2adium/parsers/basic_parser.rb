require 'pidgin2adium/log_file'
require 'pidgin2adium/messages/all'

module Pidgin2Adium
  class BasicParser
    def initialize(source_file_path, sender_aliases)
      @source_file_path = source_file_path
      # Whitespace is removed for easy matching later on.
      @sender_aliases = sender_aliases.split(',').map{|x| x.downcase.gsub(/\s+/,'') }.uniq

      # @sender_alias is set each time get_sender_by_alias is called. It is a non-normalized
      # alias.
      # Set an initial value just in case the first message doesn't give
      # us an alias.
      @sender_alias = sender_aliases.split(',')[0]
    end

    # This method returns a LogFile instance, or false if an error occurred.
    def parse
      if pre_parse
        cleaned_file_content = cleanup(@file_content).split("\n")
        cleaned_file_content.reject! { |line| line.strip.empty? }

        messages = cleaned_file_content.map do |line|
          if line =~ @line_regex
            create_message($~.captures)
          elsif line =~ @line_regex_status
            message = create_status_or_event_message($~.captures)
          end
        end
        LogFile.new(messages)
      end
    end

    # Extract required data from the file. Run by parse.
    def pre_parse
      read_source_file
      metadata = Metadata.new(MetadataParser.new(@first_line).parse)
      if metadata.valid?
        @metadata = metadata
      end
    end

    def get_sender_by_alias(alias_name)
      no_action = alias_name.sub(/^\*{3}/, '')
      if @sender_aliases.include?(no_action.downcase.gsub(/\s+/, ''))
        # Set the current alias being used of the ones in @sender_aliases
        @sender_alias = no_action
        @metadata.sender_screen_name
      else
        @metadata.receiver_screen_name
      end
    end

    #--
    # create_message takes an array of captures from matching against
    # @line_regex and returns a Message object or one of its subclasses.
    # It can be used for TextLogParser and HtmlLogParser because both of
    # they return data in the same indexes in the matches array.
    #++
    def create_message(matches)
      # Either a regular message line or an auto-reply/away message.
      time = parse_time(matches[0])
      if time
        sender_alias = matches[1]
        sender_screen_name = get_sender_by_alias(sender_alias)
        body = matches[3]
        if matches[2] # auto-reply
          AutoReplyMessage.new(sender_screen_name, time, sender_alias, body)
        else
          # normal message
          XMLMessage.new(sender_screen_name, time, sender_alias, body)
        end
      end
    end

    #--
    # create_status_or_event_message takes an array of +MatchData+ captures from
    # matching against @line_regex_status and returns an Event or Status.
    # Returns nil if it's a message that should be ignored, or false if an
    # error occurred.
    #++
    def create_status_or_event_message(matches)
      # ["22:58:00", "BuddyName logged in."]
      # 0: time
      # 1: status message or event
      time = parse_time(matches[0])
      str = matches[1]

      if time && ! ignorable_event?(str)
        create_status_message(str, time) || create_event_message(str, time)
      end
    end

    def time_parser
      @time_parser ||= TimeParser.new(@metadata.start_year, @metadata.start_month, @metadata.start_mday)
    end

    protected

    def ignorable_event?(str)
      ignore_events.detect { |regex| str =~ regex }
    end

    def create_status_message(str, time)
      regex, status = status_map.detect{|rxp, stat| str =~ rxp}
      if regex && status
        sender_alias = regex.match(str)[1]
        sender_screen_name = get_sender_by_alias(sender_alias)
        message = StatusMessage.new(sender_screen_name, time, sender_alias, status)
      end
    end

    def create_event_message(string, time)
      create_lib_purple_event_message(string, time) || create_non_lib_purple_event_message(string, time)
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
        sender_alias = @sender_alias
        sender_screen_name = @metadata.sender_screen_name
      else
        sender_alias = regex_matches[1]
        sender_screen_name = get_sender_by_alias(sender_alias)
      end
      Event.new(sender_screen_name, time, sender_alias, string, event_type)
    end

    def parse_time(time_string)
      if time_string
        time_parser.parse(time_string)
      end
    end

    def read_source_file
      if File.exist?(@source_file_path)
        open(@source_file_path) do |f|
          @first_line = f.readline
          @file_content = f.read
        end
      end
    end
  end
end
