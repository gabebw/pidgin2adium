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

    # Returns true if the time is minimal, i.e. doesn't include a date.
    # Otherwise returns false.
    def is_minimal_time?(str)
      ! str.strip.match(MINIMAL_TIME_REGEX).nil?
    end

    def try_to_parse_time(time)
      time = remove_time_zone(time)

      begin
        Time.parse(time)
      rescue ArgumentError
        try_to_parse_time_with_formats(time, NORMAL_TIME_FORMATS)
      end
    end

    def try_to_parse_minimal_time(minimal_time)
      try_to_parse_time_with_formats(minimal_time, MINIMAL_TIME_FORMATS)
    end

    private

    # Tries to parse _time_ (a string) according to the formats in _formats_, which
    # should be an array of strings. For more on acceptable format strings,
    # see the official documentation for Time.strptime. Returns a Time
    # object or nil (if no formats matched).
    def try_to_parse_time_with_formats(time, formats)
      parsed = nil
      formats.detect do |format|
        parsed = strptime(time, format)
      end
      parsed
    end

    # Returns a Time object, or nil if the format string doesn't match the
    # time string.
    def strptime(time, format)
      date_hash = Date._strptime(time, format)
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

    def remove_time_zone(time)
      time.sub(/ [A-Z]{3}/, '')
    end
  end
end
