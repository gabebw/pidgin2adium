module Pidgin2Adium
  class MetadataParser
    def initialize(first_line)
      @first_line = first_line || ''
    end

    def parse
      {
        my_screen_name: my_screen_name,
        their_screen_name: their_screen_name,
        start_time: start_time
      }
    end

    private

    def their_screen_name
      match = @first_line.match(/Conversation with (.+?) at/)
      if match
        match[1]
      end
    end

    def my_screen_name
      match = @first_line.match(/ on ([^()]+) /)
      if match
        match[1]
      end
    end

    def start_time
      match = @first_line.match(%r{ at ([-\d/APM: ]+) on})
      if match
        timestamp = match[1]
        parse_time(timestamp)
      end
    end

    def parse_time(timestamp)
      begin
        Time.parse(timestamp)
      rescue ArgumentError
        TimeParser.new(nil, nil, nil).parse(timestamp)
      end
    end
  end
end
