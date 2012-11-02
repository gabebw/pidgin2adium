describe Pidgin2Adium::HtmlLogParser do
  describe "#parse" do
    let(:path) do
      create_chat_file('parse.html') do |b|
        b.first_line :from => 'otherSN', :to => 'aolsystemmsg',
          :time => '1/15/2008 7:14:45 AM'
        b.message :time => '2008-01-15 07:14:45',
          :from_alias => 'AOL System Msg',
          :text => %{Your screen name (otherSN) is now signed into AOL(R) Instant Messenger (TM) in 2 locations. To sign off the other location(s), reply to this message with the number 1. Click <a href='http://www.aim.com/password/routing.adp'>here</a> for more information.},
          :font_color => 'A82F2F'
        b.message :time => '2008-01-15 07:14:48', :from_alias => 'Gabe B-W',
          :text => %{<span style='color: #000000;'>1</span>},
          :font_color => '16569E'
        b.message :time => '2008-01-15 07:14:48',
          :from_alias => 'AOL System Msg',
          :text => %{Your other AIM sessions have been signed-off.  You are now signed-on from 1 location(s).},
          :font_color => 'A82F2F'
      end
    end

    before do
      @chat = create_parser_for(path, 'Gabe B-W').parse
    end

    it "returns a Chat instance" do
      @chat.should be_instance_of(Pidgin2Adium::Chat)
    end

    it "returns a Chat with the correct number of lines" do
      @chat.lines.size.should == 3
    end

    it "returns a Chat with the correct message type" do
      @chat.lines.map(&:class).should == [Pidgin2Adium::XMLMessage] * 3
    end

    it "returns a Chat with the correct data" do
      first_msg = @chat.lines[0]
      second_msg = @chat.lines[1]
      third_msg = @chat.lines[2]

      first_msg.sender_screen_name.should == "aolsystemmsg"
      first_msg.sender_alias.should == "AOL System Msg"
      first_msg.time.should == DateTime.parse('2008-01-15 07:14:45')
      # This fails due to balance_tags_c().
      good_body = %Q{Your screen name (otherSN) is now signed into AOL(R) Instant Messenger (TM) in 2 locations.} + " " +
        %Q{To sign off the other location(s), reply to this message with the number 1.} + " " +
        %Q{Click <a href="http://www.aim.com/password/routing.adp">here</a> for more information.}
      first_msg.body.should == good_body

      second_msg.sender_screen_name.should == "othersn"
      second_msg.sender_alias.should == "Gabe B-W"
      second_msg.time.should == DateTime.parse('2008-01-15 07:14:48')
      second_msg.body.should == "1"

      third_msg.sender_screen_name.should == "aolsystemmsg"
      third_msg.sender_alias.should == "AOL System Msg"
      third_msg.time.should == DateTime.parse('2008-01-15 07:14:48')
      third_msg.body.should == "Your other AIM sessions have been signed-off.  You are now signed-on from 1 location(s)."
    end
  end

  def create_parser
    create_parser_for(create_chat_file('dirty.html'))
  end

  def create_parser_for(file, aliases = '')
    Pidgin2Adium::HtmlLogParser.new(file, aliases)
  end
end
