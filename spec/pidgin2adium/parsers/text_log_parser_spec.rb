describe Pidgin2Adium::TextLogParser do
  describe "#parse" do
    it "returns a Chat with the correct number of lines" do
      chat = build_chat do |b|
        b.message
      end

      chat.lines.size.should == 1
    end

    it "returns a Chat with the correct message type" do
      chat = build_chat do |b|
        b.message
      end

      chat.lines.first.should be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "returns a Chat with the correct data" do
      message = build_chat do |b|
        b.first_line time: '2006-12-21 22:36:06', from: 'awesome SN'
        b.message from_alias: 'Gabe B-W', time: '22:36:11',
          text: "what are you doing tomorrow?"
      end.lines.first

      message.sender_screen_name.should == "awesomesn"
      message.body.should == "what are you doing tomorrow?"
      message.sender_alias.should == "Gabe B-W"
      message.time.should == Time.parse('2006-12-21 22:36:11').utc
    end
  end

  def build_chat(aliases = 'Gabe B-W', &block)
    path = create_chat_file('file.txt', &block).path
    Pidgin2Adium::TextLogParser.new(path, aliases).parse
  end
end
