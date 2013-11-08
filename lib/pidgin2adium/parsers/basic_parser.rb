module Pidgin2Adium
  class BasicParser
    def initialize(source_file_path, sender_aliases, line_regex, line_regex_status, cleaner)
      @sender_aliases = sender_aliases.split(',')
      @line_regex = line_regex
      @line_regex_status = line_regex_status
      @sender_alias = @sender_aliases.first

      @file_reader = FileReader.new(source_file_path, cleaner)
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
        @alias_registry = AliasRegistry.new(@metadata.receiver_screen_name)
        @sender_aliases.each do |sender_alias|
          @alias_registry[sender_alias] = @metadata.sender_screen_name
        end
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
        sender_screen_name = @alias_registry[sender_alias]
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

    def create_event_message(text, time)
      EventMessageCreator.new(text, time, @sender_alias, @metadata.sender_screen_name, @alias_registry).create
    end

    def create_status_message(text, time)
      StatusMessageCreator.new(text, time, @alias_registry).create
    end

    def parse_time(time_string)
      if time_string
        time_parser.parse(time_string)
      end
    end
  end
end
