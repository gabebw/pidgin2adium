module Pidgin2Adium
  class BasicParser
    def initialize(source_file_path, sender_aliases)
      @sender_aliases = sender_aliases.split(',')
      @alias_registry = AliasRegistry.new

      # @sender_alias is set each time sender_from_alias is called. It is a non-normalized
      # alias.
      # Set an initial value just in case the first message doesn't give
      # us an alias.
      @sender_alias = @sender_aliases.first

      @file_reader = FileReader.new(source_file_path, Cleaners::HtmlCleaner)
    end

    # This method returns a Chat instance, or false if an error occurred.
    def parse
      if pre_parse
        messages = @file_reader.other_lines.map do |line|
          if line =~ @line_regex
            create_message($~.captures)
          elsif line =~ @line_regex_status
            message = create_status_or_event_message($~.captures)
          end
        end

        Chat.new(messages)
      end
    end

    # Extract required data from the file. Run by parse.
    def pre_parse
      @file_reader.read
      metadata = Metadata.new(MetadataParser.new(@file_reader.first_line).parse)
      if metadata.valid?
        @metadata = metadata
        @sender_aliases.each do |sender_alias|
          @alias_registry[sender_alias] = @metadata.sender_screen_name
        end
      end
    end

    def sender_from_alias(alias_name)
      if @alias_registry.key?(alias_name)
        @alias_registry[alias_name]
      else
        @alias_registry[alias_name] = @metadata.receiver_screen_name
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
        sender_screen_name = sender_from_alias(sender_alias)
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

    private

    def ignorable_event?(str)
      Event::IGNORE.any? { |regex| str =~ regex }
    end

    def create_status_message(str, time)
      regex, status = StatusMessage::MAP.detect { |rxp, stat| str =~ rxp }
      if regex && status
        sender_alias = regex.match(str)[1]
        sender_screen_name = sender_from_alias(sender_alias)
        message = StatusMessage.new(sender_screen_name, time, sender_alias, status)
      end
    end

    def create_event_message(string, time)
      create_lib_purple_event_message(string, time) || create_non_lib_purple_event_message(string, time)
    end

    def create_lib_purple_event_message(str, time)
      regex = Event::LIB_PURPLE.detect { |rxp| str =~ rxp }
      if regex
        event_type = 'libpurpleEvent'
        create_event_message_from(regex, str, time, event_type)
      end
    end

    def create_non_lib_purple_event_message(string, time)
      regex, event_type = Event::MAP.detect { |rxp,ev_type| string =~ rxp }
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
        sender_screen_name = sender_from_alias(sender_alias)
      end
      Event.new(sender_screen_name, time, sender_alias, string, event_type)
    end

    def parse_time(time_string)
      if time_string
        time_parser.parse(time_string)
      end
    end
  end
end
