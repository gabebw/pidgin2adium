module Pidgin2Adium
  class Metadata
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

    def time_string
      if line_is_present?
        @first_line.match(%r{ at ([-\d/APM: ]+) on})[1]
      end
    end

    private

    def line_is_present?
      @first_line && @first_line != ''
    end

    def valid?
      line_is_present? &&
        [receiver_screen_name, sender_screen_name, service, time_string].all?
    end
  end
end
