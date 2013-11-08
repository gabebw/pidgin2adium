describe Pidgin2Adium::Chat do
  describe '#to_s' do
    it 'converts all lines to strings and joins them' do
      chat = Pidgin2Adium::Chat.new(%w(a b c), '', Time.now)
      chat.to_s.should == 'abc'
    end
  end

  it 'is enumerable' do
    chat = Pidgin2Adium::Chat.new(%w(a b c), '', Time.now)
    chat.map(&:upcase).should == %w(A B C)
  end

  describe '#their_screen_name' do
    it 'is the screen name of the other person in the chat' do
      chat = Pidgin2Adium::Chat.new([], 'them', Time.now)

      chat.their_screen_name.should == 'them'
    end
  end

  describe '#start_time_xmlschema' do
    it 'is the start time of the chat in xmlschema format' do
      time = Time.now
      chat = Pidgin2Adium::Chat.new([], 'them', time)

      chat.start_time_xmlschema.should == time.xmlschema
    end
  end
end
