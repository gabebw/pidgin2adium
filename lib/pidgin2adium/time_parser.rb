module Pidgin2Adium
  class TimeParser
    NO_DATE_REGEX = /\A\d{1,2}:\d{1,2}:\d{1,2}(?: [AP]M)?\Z/

    # 01/22/2008 03:01:45 PM
    UNPARSEABLE_BY_DATETIME_PARSE = '%m/%d/%Y %I:%M:%S %P'

    def initialize(year, month, day)
      @fallback_date_string = "#{year}-#{month}-#{day}"
    end

    def parse(time_string)
      if has_no_date?(time_string)
        parse_with_date(@fallback_date_string + " " + time_string)
      else
        parse_with_date(time_string)
      end
    end

    private

    def parse_with_date(time_string)
      begin
        Time.parse(time_string)
      rescue ArgumentError
        Time.strptime(time_string, UNPARSEABLE_BY_DATETIME_PARSE)
      end
    end

    def has_no_date?(time_string)
      time_string.strip =~ NO_DATE_REGEX
    end
  end
end
