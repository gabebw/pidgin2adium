describe Pidgin2Adium::Chat do
  describe '#to_s' do
    it 'converts all lines to strings and joins them' do
      chat = Pidgin2Adium::Chat.new(%w(a b c), '')
      chat.to_s.should == 'abc'
    end
  end

  it 'is enumerable' do
    chat = Pidgin2Adium::Chat.new(%w(a b c), '')
    chat.map(&:upcase).should == %w(A B C)
  end

  describe '#their_screen_name' do
    it 'is the screen name of the other person in the chat' do
      chat = Pidgin2Adium::Chat.new([], 'them')

      chat.their_screen_name.should == 'them'
    end
  end
end
