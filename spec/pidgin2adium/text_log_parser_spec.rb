require 'spec_helper'

describe Pidgin2Adium::TextLogParser do
  it "should cleanup text correctly" do
    time = '(04:20:06)'
    dirty_text = %Q{\r\n#{time}&<b>Hello!</b> "Hi!" 'Oh no'\n}
    # "\n" not removed if it ends a line or is followed by
    # a timestamp
    clean_text = %Q{\n#{time}&amp;&lt;b&gt;Hello!&lt;/b&gt; &quot;Hi!&quot; &apos;Oh no&apos;\n}
    create_parser.cleanup(dirty_text).should == clean_text
  end

  describe "#parse" do
    it "should return a Chat instance" do
      create_parser.parse.should be_instance_of(Pidgin2Adium::Chat)
    end

    it "should return a Chat with the correct number of lines" do
      path = create_chat_file('one_message.txt') do |b|
        b.message
      end
      chat = create_parser_for(path).parse
      chat.lines.size.should == 1
    end

    it "should return a Chat with the correct message type" do
      path = create_chat_file('xml_message.txt') do |b|
        b.message
      end
      chat = create_parser_for(path).parse
      chat.lines[0].should be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "should return a Chat with the correct data" do
      path = create_chat_file('chat.txt') do |b|
        b.first_line :time => '2006-12-21 22:36:06', :from => 'awesome SN'
        b.message :from_alias => 'Gabe B-W', :time => '22:36:11',
          :text => "what are you doing tomorrow?"
      end
      chat = create_parser_for(path, 'Gabe B-W').parse
      msg = chat.lines[0]
      msg.sender_screen_name.should == "awesomesn"
      msg.body.should == "what are you doing tomorrow?"
      msg.sender_alias.should == "Gabe B-W"
      msg.time.should == Time.parse('2006-12-21 22:36:11').utc
    end
  end

  def create_parser
    create_parser_for(create_chat_file('log.txt'))
  end

  def create_parser_for(file, aliases = '')
    Pidgin2Adium::TextLogParser.new(file, aliases)
  end
end
