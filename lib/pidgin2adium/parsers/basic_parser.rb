module Pidgin2Adium
  class BasicParser
    def initialize(source_file_path, my_aliases, line_regex, line_regex_status, cleaner)
      @my_aliases = my_aliases.split(',')
      @line_regex = line_regex
      @line_regex_status = line_regex_status
      @my_alias = @my_aliases.first

      @file_reader = FileReader.new(source_file_path, cleaner)
    end

    # This method returns a Chat instance, or false if it could not parse the
    # file.
    def parse
      if pre_parse
        messages = @file_reader.other_lines.map do |line|
          basic_message_match =  @line_regex.match(line)
          meta_message_match = @line_regex_status.match(line)
          if basic_message_match
            create_message(basic_message_match)
          elsif meta_message_match
            create_status_or_event_message(meta_message_match)
          end
        end

        Chat.new(messages, @metadata.their_screen_name, @metadata.start_time)
      end
    end

    # Extract required data from the file. Run by parse.
    def pre_parse
      @file_reader.read
      metadata = Metadata.new(MetadataParser.new(@file_reader.first_line).parse)
      if metadata.valid?
        @metadata = metadata
        @alias_registry = AliasRegistry.new(@metadata.their_screen_name)
        @my_aliases.each do |my_alias|
          @alias_registry[my_alias] = @metadata.my_screen_name
        end
      end
    end

    def create_message(match_data)
      # Either a regular message line or an auto-reply/away message.
      time = time_parser.parse(match_data[:timestamp])
      if time
        my_alias = match_data[:sn_or_alias]
        my_screen_name = @alias_registry[my_alias]
        body = match_data[:body]
        is_auto_reply = match_data[:auto_reply]

        AutoOrXmlMessageCreator.new(body, time, my_screen_name, my_alias, is_auto_reply).create
      end
    end

    def create_status_or_event_message(match_data)
      time = time_parser.parse(match_data[:timestamp])
      str = match_data[:body]

      if time && event_we_care_about?(str)
        create_status_message(str, time) || create_event_message(str, time)
      end
    end

    def time_parser
      @time_parser ||= TimeParser.new(@metadata.start_year, @metadata.start_month, @metadata.start_mday)
    end

    private

    def event_we_care_about?(str)
      Event::IGNORE.none? { |regex| str =~ regex }
    end

    def create_event_message(text, time)
      EventMessageCreator.new(text, time, @my_alias, @metadata.my_screen_name, @alias_registry).create
    end

    def create_status_message(text, time)
      StatusMessageCreator.new(text, time, @alias_registry).create
    end
  end
end
