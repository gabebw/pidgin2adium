describe Pidgin2Adium::MetadataParser do
  context '#parse' do
    it "finds the sender's screen name" do
      path = create_chat_file('log.html') do |b|
        b.first_line from: 'JIM'
      end
      metadata = Pidgin2Adium::MetadataParser.new(first_line_of(path)).parse
      metadata[:sender_screen_name].should == 'JIM'
    end

    it "finds the receiver's screen name" do
      path = create_chat_file('log.html') do |b|
        b.first_line to: 'lady anne'
      end
      metadata = Pidgin2Adium::MetadataParser.new(first_line_of(path)).parse
      metadata[:receiver_screen_name].should == 'lady anne'
    end

    it 'finds the start time' do
      time_string = '2008-04-01 22:36:06'
      path = create_chat_file('log.html') do |b|
        b.first_line time: time_string
      end
      metadata = Pidgin2Adium::MetadataParser.new(first_line_of(path)).parse
      metadata[:start_time].should == DateTime.parse(time_string)
    end

    it 'can detect peculiar times' do
      time_string = "1/15/2008 7:14:45 AM"
      expected_time = Time.parse('2008-01-15 07:14:45')
      path = create_chat_file('log.html') do |b|
        b.first_line time: time_string
      end
      metadata = Pidgin2Adium::MetadataParser.new(first_line_of(path)).parse
      metadata[:start_time].should == expected_time
    end

    it 'sets all attributes to nil when initialized with an empty string' do
      metadata = Pidgin2Adium::MetadataParser.new('').parse
      assert_all_attributes_nil(metadata)
    end

    it 'sets all attributes to nil when initialized with nil' do
      metadata = Pidgin2Adium::MetadataParser.new(nil).parse
      assert_all_attributes_nil(metadata)
    end

    it 'rsets all attributes to nil when given a non-standard file to parse' do
      path = create_file('nonstandard.html') do |f|
        f.write '<HTML><BODY BGCOLOR="#ffffff"><B><FONT COLOR="#ff0000" LANG="0">jiggerific bug<!-- (3:22:29 PM)--></B></FONT><FONT COLOR="#ff0000" BACK="#ffffff">:</FONT><FONT COLOR="#000000"> try direct IM now</FONT><BR>'
      end
      metadata = Pidgin2Adium::MetadataParser.new(path).parse
      assert_all_attributes_nil(metadata)
    end
  end

  def first_line_of(path)
    File.readlines(path).first
  end

  def assert_all_attributes_nil(metadata)
    metadata[:start_time].should be_nil
    metadata[:receiver_screen_name].should be_nil
    metadata[:sender_screen_name].should be_nil
  end
end
