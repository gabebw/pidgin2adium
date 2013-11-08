module Pidgin2Adium
  class MetadataParser
    # "4/18/2007 11:02:00 AM" becomes %w(4 18 2007)
    TIME_REGEX_FIRST_LINE = %r{^(\d{1,2})/(\d{1,2})/(\d{4}) \d{1,2}:\d{2}:\d{2} [AP]M$}

    def initialize(first_line)
      @first_line = first_line || ''
    end

    def parse
      {
        sender_screen_name: sender_screen_name,
        receiver_screen_name: receiver_screen_name,
        start_time: start_time
      }
    end

    private

    def receiver_screen_name
      match = @first_line.match(/Conversation with (.+?) at/)
      if match
        match[1]
      end
    end

    def sender_screen_name
      match = @first_line.match(/ on ([^()]+) /)
      if match
        match[1]
      end
    end

    def start_time
      match = @first_line.match(%r{ at ([-\d/APM: ]+) on})
      if match
        time_string = match[1]
        parse_time(time_string)
      end
    end

    def parse_time(time_string)
      begin
        Time.parse(time_string)
      rescue ArgumentError
        matches = time_string.match(TIME_REGEX_FIRST_LINE)
        if matches
          year = matches[1]
          month = matches[2]
          day = matches[3]
          time_parser = TimeParser.new(year, month, day)
          time_parser.parse(time_string)
        end
      end
    end
  end
end
