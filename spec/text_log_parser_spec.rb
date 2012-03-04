require 'spec_helper'

describe Pidgin2Adium::TextLogParser do
  before do
    @time = '(04:20:06)'
    @tlp = Pidgin2Adium::TextLogParser.new(@text_logfile_path,
                                           @aliases)
  end
  it "should cleanup text correctly" do
    dirty_text = %Q{\r\n#{@time}&<b>Hello!</b> "Hi!" 'Oh no'\n}
    # "\n" not removed if it ends a line or is followed by
    # a timestamp
    clean_text = %Q{\n#{@time}&amp;&lt;b&gt;Hello!&lt;/b&gt; &quot;Hi!&quot; &apos;Oh no&apos;\n}
    @tlp.cleanup(dirty_text).should == clean_text
  end

  describe "#parse" do
    it "should return a LogFile instance" do
      @tlp.parse().should be_instance_of(Pidgin2Adium::LogFile)
    end

    it "should return a LogFile with the correct number of chat_lines" do
      logfile = @tlp.parse
      logfile.chat_lines.size.should == 1
    end

    it "should return a LogFile with the correct message type" do
      logfile = @tlp.parse
      logfile.chat_lines[0].should be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "should return a LogFile with the correct data" do
      logfile = @tlp.parse
      msg = logfile.chat_lines[0]
      msg.sender.should == "awesomesn"
      msg.body.should == "what are you doing tomorrow?"
      msg.buddy_alias.should == "Gabe B-W"
      msg.time.should include '2006-12-21T22:36:11'
    end
  end
end
