module Pidgin2Adium
  class Metadata
    # "4/18/2007 11:02:00 AM" => %w(4 18 2007)
    TIME_REGEX_FIRST_LINE = %r{^(\d{1,2})/(\d{1,2})/(\d{4}) \d{1,2}:\d{2}:\d{2} [AP]M$}

    def initialize(first_line)
      @first_line = first_line
    end

    def invalid?
      ! valid?
    end

    def receiver_screen_name
      if line_is_present?
        @first_line.match(/Conversation with (.+?) at/)[1]
      end
    end

    def sender_screen_name
      if line_is_present?
        screen_name = @first_line.match(/ on ([^()]+) /)[1]
        screen_name.downcase.gsub(' ', '')
      end
    end

    def service
      if line_is_present?
        @first_line.match(/\(([a-z]+)\)/)[1]
      end
    end

    def start_time
      if line_is_present?
        time_string = @first_line.match(%r{ at ([-\d/APM: ]+) on})[1]
        parse_time(time_string)
      end
    end

    private

    def parse_time(time_string)
      begin
        DateTime.parse(time_string)
      rescue ArgumentError
        matches = time_string.match(TIME_REGEX_FIRST_LINE)
        year = matches[1]
        month = matches[2]
        day = matches[3]
        time_parser = TimeParser.new(year, month, day)
        time_parser.parse(time_string)
      end
    end

    def line_is_present?
      @first_line && @first_line != ''
    end

    def valid?
      line_is_present? &&
        [receiver_screen_name, sender_screen_name, service, start_time].all?
    end
  end
end
