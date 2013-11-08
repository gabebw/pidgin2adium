describe Pidgin2Adium::Metadata do
  context '#my_screen_name' do
    it "returns my normalized screen name" do
      metadata = Pidgin2Adium::Metadata.new(my_screen_name: 'JIM BOB')
      metadata.my_screen_name.should == 'jimbob'
    end
  end

  context '#their_screen_name' do
    it "returns their screen name" do
      metadata = Pidgin2Adium::Metadata.new(their_screen_name: 'lady anne')
      metadata.their_screen_name.should == 'lady anne'
    end
  end

  context '#start_time' do
    it 'returns the start time' do
      time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: time)

      metadata.start_time.should == time
    end
  end

  context '#start_month' do
    it 'returns the start month' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: start_time)
      metadata.start_month.should == start_time.mon
    end
  end

  context '#start_year' do
    it 'returns the start year' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: start_time)
      metadata.start_year.should == start_time.year
    end
  end

  context '#start_mday' do
    it 'returns the start mday' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: start_time)
      metadata.start_mday.should == start_time.mday
    end
  end

  context '#valid?' do
    it 'is true when all attributes are provided' do
      metadata = Pidgin2Adium::Metadata.new({my_screen_name: '',
        their_screen_name: '',
        start_time: '' })
      metadata.should be_valid
    end

    [:my_screen_name, :their_screen_name, :start_time].each do |attribute|
      it "is false when #{attribute} cannot be detected" do
        Pidgin2Adium::Metadata.new(attribute => nil).should_not be_valid
      end
    end
  end
end
