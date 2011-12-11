require 'date'
require 'time'

module Pidgin2Adium
  class TimeConverter
    def initialize(datetime, year_month_day = {})
      @datetime = datetime
      @year, @month, @day = year_month_day[:year], year_month_day[:month], year_month_day[:day]
    end

    def to_adium
      if first_line_time?
        iso8601_version_of(DateTime.strptime(@datetime, first_line_time_format))
      elsif normal_time?
        iso8601_version_of(DateTime.strptime(@datetime, normal_time_format))
      elsif twelve_hour_minimal_time?
        full_time = "#{@year}-#{@month}-#{@day} #{@datetime}"
        iso8601_version_of(DateTime.strptime(full_time, '%F %r'))
      elsif twenty_four_hour_minimal_time?
        full_time = "#{@year}-#{@month}-#{@day} #{@datetime}"
        iso8601_version_of(DateTime.strptime(full_time, '%F %T'))
      end
    end

    private

    def first_line_time?
      @datetime =~ %r{\d/\d{2}/\d{4} \d{2}:\d{2}:\d{2} AM}
    end

    def first_line_time_format
      '%m/%d/%Y %I:%M:%S %p'
    end

    def normal_time?
      @datetime =~ %r{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}
    end

    def normal_time_format
      '%F %T'
    end

    def twelve_hour_minimal_time?
      @datetime =~ %r{\d{2}:\d{2}:\d{2} AM}
    end

    def twenty_four_hour_minimal_time?
      @datetime =~ %r{\d{2}:\d{2}:\d{2}}
    end

    def iso8601_version_of(datetime)
      datetime.strftime('%Y-%m-%dT%H:%M:%S%Z')
    end
  end
end
