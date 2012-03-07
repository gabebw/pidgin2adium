require 'spec_helper'

describe Pidgin2Adium::TimeParser, "#parse" do
  context 'when the given time does have a date' do
    let(:time_parser) { Pidgin2Adium::TimeParser.new(2011, 4, 28) }

    it 'parses "%m/%d/%Y %I:%M:%S %P"' do
      time = '01/22/2008 03:01:45 PM'
      result = time_parser.parse(time)
      result.year.should == 2008
      result.mon.should == 1
      result.mday.should == 22
      result.hour.should == 15
      result.min.should == 1
      result.sec.should == 45
    end

    it 'parses "%Y-%m-%d %H:%M:%S"' do
      time = '2008-01-22 23:08:24'
      time_parser.parse(time).should == DateTime.parse(time)
    end

    it 'parses "%Y/%m/%d %H:%M:%S"' do
      time = '2008/01/22 04:01:45'
      time_parser.parse(time).should == DateTime.parse(time)
    end

    it 'parses "%Y-%m-%d %H:%M:%S"' do
      time = '2008-01-22 04:01:45'
      time_parser.parse(time).should == DateTime.parse(time)
    end

    it 'parses "%a %d %b %Y %H:%M:%S %p %Z", ignoring time zones' do
      time = "Sat 18 Apr 2009 10:43:35 AM PDT"
      time_without_zone = time.sub('PDT', '')
      parsed_time = DateTime.parse(time_without_zone)
      parsed_time.hour.should == 10
      time_parser.parse(time).should == parsed_time
    end

    it 'parses "%a %b %d %H:%M:%S %Y"' do
      time = "Wed May 24 19:00:33 2006"
      time_parser.parse(time).should == DateTime.parse(time)
    end
  end

  context 'when the given time does not have a date' do
    let(:time_parser) { Pidgin2Adium::TimeParser.new(2008, 4, 27) }

    it 'parses "%I:%M:%S %P"' do
      result = time_parser.parse('08:01:45 PM')
      result.year.should == 2008
      result.mon.should == 4
      result.mday.should == 27
      result.hour.should == 20
      result.min.should == 1
      result.sec.should == 45
    end

    it 'parses "%H:%M:%S"' do
      result = time_parser.parse('23:01:45')
      result.year.should == 2008
      result.mon.should == 4
      result.mday.should == 27
      result.hour.should == 23
      result.min.should == 1
      result.sec.should == 45
    end
  end
end

describe Pidgin2Adium::TimeParser, "#parse_into_adium_format" do
  let(:time_parser) { Pidgin2Adium::TimeParser.new(2011, 4, 28) }

  it 'parses into xmlschema format' do
    time_string = '2008-01-22 03:01:45 PM'
    formatted_time = DateTime.parse(time_string).strftime('%Y-%m-%dT%H:%M:%S%Z')
    result = time_parser.parse_into_adium_format(time_string)
    result.should == formatted_time
  end

  it 'returns nil when it cannot parse the given time' do
    result = time_parser.parse_into_adium_format('foobar')
    result.should be_nil
  end
end
