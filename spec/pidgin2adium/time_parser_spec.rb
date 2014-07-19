describe Pidgin2Adium::TimeParser, "#parse" do
  it 'returns nil when timestamp is nil' do
    time_parser = Pidgin2Adium::TimeParser.new(2011, 2, 3)

    expect(time_parser.parse(nil)).to be_nil
  end

  context 'when the given timestamp does have a date' do
    let(:time_parser) { Pidgin2Adium::TimeParser.new(2011, 4, 28) }

    it 'parses "%m/%d/%Y %I:%M:%S %P"' do
      timestamp = '01/22/2008 03:01:45 PM'
      result = time_parser.parse(timestamp)
      expect(result.year).to eq(2008)
      expect(result.mon).to eq(1)
      expect(result.mday).to eq(22)
      expect(result.hour).to eq(15)
      expect(result.min).to eq(1)
      expect(result.sec).to eq(45)
    end

    [
      '%Y-%m-%d %H:%M:%S',
      '%Y/%m/%d %H:%M:%S',
      '%Y-%m-%d %H:%M:%S',
      '%a %b %d %H:%M:%S %Y'
    ].each do |format|
      it "parses '#{format}'" do
        time = Time.now
        timestamp = time.strftime(format)
        expect(time_parser.parse(timestamp)).to eq(Time.parse(timestamp))
      end
    end

    it 'parses "%a %d %b %Y %H:%M:%S %p %Z", respecting TZ' do
      timestamp = "Sat 18 Apr 2009 10:43:35 AM PDT"
      time = Time.parse(timestamp)
      expect(time.utc.hour).to eq(17)
      expect(time_parser.parse(timestamp)).to eq(time)
    end
  end

  context 'when the given timestamp does not have a date' do
    let(:time_parser) { Pidgin2Adium::TimeParser.new(2008, 4, 27) }

    it 'parses "%I:%M:%S %P"' do
      result = time_parser.parse('08:01:45 PM')
      expect(result.year).to eq(2008)
      expect(result.mon).to eq(4)
      expect(result.mday).to eq(27)
      expect(result.hour).to eq(20)
      expect(result.min).to eq(1)
      expect(result.sec).to eq(45)
    end

    it 'parses "%H:%M:%S"' do
      result = time_parser.parse('23:01:45')
      expect(result.year).to eq(2008)
      expect(result.mon).to eq(4)
      expect(result.mday).to eq(27)
      expect(result.hour).to eq(23)
      expect(result.min).to eq(1)
      expect(result.sec).to eq(45)
    end
  end
end
