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

    [
      '%Y-%m-%d %H:%M:%S',
      '%Y/%m/%d %H:%M:%S',
      '%Y-%m-%d %H:%M:%S',
      '%a %b %d %H:%M:%S %Y'
    ].each do |format|
      it "parses '#{format}'" do
        time = Time.now
        time_string = time.strftime(format)
        time_parser.parse(time_string).should == Time.parse(time_string)
      end
    end

    it 'parses "%a %d %b %Y %H:%M:%S %p %Z", respecting TZ' do
      time = "Sat 18 Apr 2009 10:43:35 AM PDT"
      parsed_time = Time.parse(time)
      parsed_time.utc.hour.should == 17
      time_parser.parse(time).should == parsed_time
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
