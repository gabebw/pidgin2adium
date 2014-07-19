describe Pidgin2Adium::Metadata do
  context '#my_screen_name' do
    it "returns my normalized screen name" do
      metadata = Pidgin2Adium::Metadata.new(my_screen_name: 'JIM BOB')
      expect(metadata.my_screen_name).to eq('jimbob')
    end
  end

  context '#their_screen_name' do
    it "returns their screen name" do
      metadata = Pidgin2Adium::Metadata.new(their_screen_name: 'lady anne')
      expect(metadata.their_screen_name).to eq('lady anne')
    end
  end

  context '#start_time' do
    it 'returns the start time' do
      time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: time)

      expect(metadata.start_time).to eq(time)
    end
  end

  context '#start_month' do
    it 'returns the start month' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: start_time)
      expect(metadata.start_month).to eq(start_time.mon)
    end
  end

  context '#start_year' do
    it 'returns the start year' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: start_time)
      expect(metadata.start_year).to eq(start_time.year)
    end
  end

  context '#start_mday' do
    it 'returns the start mday' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(start_time: start_time)
      expect(metadata.start_mday).to eq(start_time.mday)
    end
  end

  context '#valid?' do
    it 'is true when all attributes are provided' do
      metadata = Pidgin2Adium::Metadata.new({my_screen_name: '',
        their_screen_name: '',
        start_time: '' })
      expect(metadata).to be_valid
    end

    [:my_screen_name, :their_screen_name, :start_time].each do |attribute|
      it "is false when #{attribute} cannot be detected" do
        expect(Pidgin2Adium::Metadata.new(attribute => nil)).not_to be_valid
      end
    end
  end
end
