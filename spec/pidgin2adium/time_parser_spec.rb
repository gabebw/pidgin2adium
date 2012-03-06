require 'spec_helper'

describe Pidgin2Adium::TimeParser, "#try_to_parse_time" do
  let(:time_parser) { Pidgin2Adium::TimeParser.new(2011, 4, 28) }

  it 'parses "%m/%d/%Y %I:%M:%S %P"' do
    time = '01/22/2008 03:01:45 PM'
    parseable_time = '2008-01-22 03:01:45 PM'
    time_parser.try_to_parse_time(time).should == Time.parse(parseable_time)
  end

  it 'parses "%Y-%m-%d %H:%M:%S"' do
    time = '2008-01-22 23:08:24'
    time_parser.try_to_parse_time(time).should == Time.parse(time)
  end

  it 'parses "%Y/%m/%d %H:%M:%S"' do
    time = '2008/01/22 04:01:45'
    time_parser.try_to_parse_time(time).should == Time.parse(time)
  end

  it 'parses "%Y-%m-%d %H:%M:%S"' do
    time = '2008-01-22 04:01:45'
    time_parser.try_to_parse_time(time).should == Time.parse(time)
  end

  it 'parses "%a %d %b %Y %H:%M:%S %p %Z", ignoring time zones' do
    time = "Sat 18 Apr 2009 10:43:35 AM PDT"
    time_without_zone = time.sub('PDT', '')
    parsed_time = Time.parse(time_without_zone)
    parsed_time.hour.should == 10
    time_parser.try_to_parse_time(time).should == parsed_time
  end

  it 'parses "%a %b %d %H:%M:%S %Y"' do
    time = "Wed May 24 19:00:33 2006"
    time_parser.try_to_parse_time(time).should == Time.parse(time)
  end
end

describe Pidgin2Adium::TimeParser, "#try_to_parse_minimal_time" do
  let(:time_parser) { Pidgin2Adium::TimeParser.new(2008, 4, 27) }

  it 'parses "%I:%M:%S %P"' do
    result = time_parser.try_to_parse_minimal_time('08:01:45 PM')
    result.year.should == 2008
    result.mday.should == 27
    result.mon.should == 4
    result.hour.should == 20
    result.min.should == 1
    result.sec.should == 45
  end

  it 'parses "%H:%M:%S"' do
    result = time_parser.try_to_parse_minimal_time('23:01:45')
    result.year.should == 2008
    result.mday.should == 27
    result.mon.should == 4
    result.hour.should == 23
    result.min.should == 1
    result.sec.should == 45
  end
end

describe Pidgin2Adium::BasicParser, "#is_minimal_time?" do
  let(:time_parser) { Pidgin2Adium::TimeParser.new(2011, 4, 28) }

  it 'returns true for a time like 03:04:08' do
    time_parser.is_minimal_time?('03:04:08').should be
  end

  it 'returns true for a time like 03:04:08 AM' do
    time_parser.is_minimal_time?('03:04:08 AM').should be
  end

  it 'returns true for a time like 03:04:08 PM' do
    time_parser.is_minimal_time?('03:04:08 PM').should be
  end

  it 'strips space before parsing' do
    time_parser.is_minimal_time?('  03:04:08  ').should be
  end

  it 'returns false for other times' do
    time_parser.is_minimal_time?('2006-08-02 03:04:08').should_not be
  end
end
