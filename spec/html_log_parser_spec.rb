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

=begin
  describe "#parse" do
    it "should return a LogFile instance" do
      @hlp.parse().should be_instance_of(Pidgin2Adium::LogFile)
    end

    it "should return a LogFile with the correct number of chat_lines" do
      logfile = @hlp.parse
      logfile.chat_lines.size.should == 1
    end

    it "should return a LogFile with the correct message type" do
      logfile = @hlp.parse
      logfile.chat_lines[0].should be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "should return a LogFile with the correct data" do
      logfile = @hlp.parse
      msg = logfile.chat_lines[0]
      msg.sender.should == "awesomesn"
      msg.body.should == "what are you doing tomorrow?"
      msg.buddy_alias.should == "Gabe B-W"
      # Use regex to ignore time zone
      msg.time.should =~ /^2006-12-21T22:36:11[-+]\d{2}00$/
    end
  end
=end
end
