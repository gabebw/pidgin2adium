require 'spec_helper'

describe "HtmlLogParser" do
  before(:each) do
    # @year, @am, and @pm are not required. @time is.
    # So @year + @time is a valid time,
    # as is @time, and @year + @time + @am.
    @year = '2007-10-28 '
    @time = '4:46:20'
    @am = ' AM'
    @pm = ' PM'
    @hlp = Pidgin2Adium::HtmlLogParser.new(@html_logfile_path,
                                           @aliases)
    @clean = "clean"
  end

  it "should have Pidgin2Adium.balance_tags_c available" do
    Pidgin2Adium.should respond_to(:balance_tags_c)
  end

  describe "#cleanup" do
    it "should remove html, body, and font tags" do
      dirty_text = %Q{<html><body type="ichat"><font color="red">#{@clean}</font></body></html>}
      @hlp.cleanup(dirty_text).should == @clean
    end

    it "should remove those weird <FONT HSPACE> tags" do
      dirty = %Q{&lt;/FONT HSPACE='2'>#{@clean}}
      @hlp.cleanup(dirty).should == @clean
    end

    it "should remove \\r" do
      dirty = [@clean, @clean, @clean].join("\r")
      @hlp.cleanup(dirty).should == @clean * 3
    end

    it "should remove empty lines" do
      dirty = "#{@clean}\n\n"
      @hlp.cleanup(dirty).should == @clean
    end

    it "should replace newlines with <br/>" do
      dirty = "\n#{@clean}"
      @hlp.cleanup(dirty).should == "<br/>#{@clean}"
    end

    it "should remove empty links" do
      dirty = %Q{<a href="awesomelink">   </a>#{@clean}}
      dirty += %Q{<a href='awesomelink'></a>#{@clean}}
      @hlp.cleanup(dirty).should == @clean + @clean
    end

    describe "with <span>s" do
      it "should remove font-family" do
        dirty = %Q{<span style='font-family: Helvetica;'>#{@clean}</span>}
        @hlp.cleanup(dirty).should == @clean
      end

      it "should remove font-size" do
        dirty = %Q{<span style="font-size: 6;">#{@clean}</span>}
        @hlp.cleanup(dirty).should == @clean
      end

      it "should remove background" do
        dirty = %Q{<span style="background: #00afaf;">#{@clean}</span>}
        @hlp.cleanup(dirty).should == @clean
      end

      it "should remove color=#00000" do
        dirty = %Q{<span style="color: #000000;">#{@clean}</span>}
        @hlp.cleanup(dirty).should == @clean
      end

      it "should not remove color != #00000" do
        dirty = %Q{<span style="color: #01ABcdef;">#{@clean}</span>}
        @hlp.cleanup(dirty).should == dirty
      end

      it "should remove improperly-formatted colors" do
        dirty = %Q{<span style="color: #0;">#{@clean}</span>}
        @hlp.cleanup(dirty).should == @clean
      end

      it "should replace <em> with italic font-style" do
        dirty = "<em>#{@clean}</em>"
        clean = %Q{<span style="font-style: italic;">#{@clean}</span>}
        @hlp.cleanup(dirty).should == clean
      end

      it "shouldn't modify clean text" do
        @hlp.cleanup(@clean).should == @clean
      end

      # This implicitly tests a lot of other things, but they've been tested
      # before this too.
      it "should remove a trailing space after style declaration and replace double quotes" do
        dirty_span_open = "<span style='color: #afaf00; font-size: 14pt; font-weight: bold; '>"
        # Replaced double quotes, removed space before ">"
        clean_span_open = '<span style="color: #afaf00;">'
        dirty = dirty_span_open + @clean + "</span>"
        @hlp.cleanup(dirty).should == clean_span_open + @clean + "</span>"
      end
    end
  end

  describe "#parse" do
    before(:each) do
      @logfile = @hlp.parse()
    end

    it "should return a LogFile instance" do
      @logfile.should be_instance_of(Pidgin2Adium::LogFile)
    end

    it "should return a LogFile with the correct number of chat_lines" do
      @logfile.chat_lines.size.should == 3
    end

    it "should return a LogFile with the correct message type" do
      @logfile.chat_lines.map{|x| x.class }.should == [Pidgin2Adium::XMLMessage] * 3
    end

    it "should return a LogFile with the correct data" do
      first_msg = @logfile.chat_lines[0]
      second_msg = @logfile.chat_lines[1]
      third_msg = @logfile.chat_lines[2]

      first_msg.sender.should == "aolsystemmsg"
      first_msg.buddy_alias.should == "AOL System Msg"
      # Use regex to ignore time zone
      first_msg.time.should =~ /^2008-01-15T07:14:45[-+]\d{2}00$/
      # This fails due to balance_tags_c().
      good_body = %Q{Your screen name (otherSN) is now signed into AOL(R) Instant Messenger (TM) in 2 locations.} + " " +
        %Q{To sign off the other location(s), reply to this message with the number 1.} + " " +
        %Q{Click <a href="http://www.aim.com/password/routing.adp">here</a> for more information.}
      first_msg.body.should == good_body

      second_msg.sender.should == "othersn"
      second_msg.buddy_alias.should == "Gabe B-W"
      second_msg.time.should =~ /^2008-01-15T07:14:48[-+]\d{2}00$/
      second_msg.body.should == "1"

      third_msg.sender.should == "aolsystemmsg"
      third_msg.buddy_alias.should == "AOL System Msg"
      # Use regex to ignore time zone
      third_msg.time.should =~ /^2008-01-15T07:14:48[-+]\d{2}00$/
      third_msg.body.should == "Your other AIM sessions have been signed-off.  You are now signed-on from 1 location(s)."
    end
  end
end
