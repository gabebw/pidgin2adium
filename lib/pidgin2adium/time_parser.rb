module Pidgin2Adium
  class TimeParser
    # Minimal times don't have a date
    MINIMAL_TIME_REGEX = /^\d{1,2}:\d{1,2}:\d{1,2}(?: [AP]M)?$/

    NORMAL_TIME_FORMATS = [
      "%m/%d/%Y %I:%M:%S %P", # 01/22/2008 03:01:45 PM
    ]

    MINIMAL_TIME_FORMATS = [
      "%I:%M:%S %P", # 04:01:45 AM
      "%H:%M:%S" # 23:01:45
    ]

    def initialize(year, month, day)
      @year = year
      @month = month
      @day = day
    end

    def parse(time_string)
      time_string_without_zone = remove_time_zone(time_string)
      if includes_date?(time_string)
        parse_time_with_date(time_string_without_zone)
      else
        parse_time_without_date(time_string_without_zone)
      end
    end

    def parse_into_adium_format(time_string)
      parsed = parse(time_string)
      if parsed
        parsed.strftime('%Y-%m-%dT%H:%M:%S%Z')
      else
        nil
      end
    end

    private

    def parse_time_with_date(time_string)
      begin
        DateTime.parse(time_string)
      rescue ArgumentError
        parse_time_with_formats(time_string, NORMAL_TIME_FORMATS)
      end
    end

    def parse_time_without_date(minimal_time_string)
      parse_time_with_formats(minimal_time_string, MINIMAL_TIME_FORMATS)
    end

    # Tries to parse _time_ (a string) according to the formats in _formats_, which
    # should be an array of strings. For more on acceptable format strings,
    # see the official documentation for Time.strptime. Returns a Time
    # object or nil (if no formats matched).
    def parse_time_with_formats(time_string, formats)
      parsed = nil
      formats.detect do |format|
        parsed = strptime(time_string, format)
      end
      parsed
    end

    # Returns a Time object, or nil if the format string doesn't match the
    # time string.
    def strptime(time_string, format)
      date_hash = Date._strptime(time_string, format)
      if date_hash.nil?
        nil
      else
        date_hash = fill_in_year_month_day_if_absent(date_hash)
        time = Time.local(date_hash[:year], date_hash[:mon], date_hash[:mday],
                          date_hash[:hour], date_hash[:min], date_hash[:sec],
                          date_hash[:sec_fraction], date_hash[:zone])
        time
      end
    end

    def fill_in_year_month_day_if_absent(date_hash)
      { :year => @year, :mon => @month, :mday => @day }.merge(date_hash)
    end

    def remove_time_zone(time_string)
      time_string.sub(/ [A-Z]{3}/, '')
    end

    def includes_date?(time_string)
      time_string.strip.match(MINIMAL_TIME_REGEX).nil?
    end
  end
end
