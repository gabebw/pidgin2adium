require 'spec_helper'

describe "HtmlLogParser" do
  describe "#cleanup" do
    it "should remove html, body, and font tags" do
      clean_text = 'clean'
      dirty_text = %Q{<html><body type="ichat"><font color="red">#{clean_text}</font></body></html>}
      create_parser.cleanup(dirty_text).should == clean_text
    end

    it "should remove those weird <FONT HSPACE> tags" do
      clean_text = 'clean'
      dirty_text = %Q{&lt;/FONT HSPACE='2'>#{clean_text}}
      create_parser.cleanup(dirty_text).should == clean_text
    end

    it "should remove \\r" do
      clean_text = 'clean'
      dirty_text = [clean_text, clean_text, clean_text].join("\r")
      create_parser.cleanup(dirty_text).should == clean_text * 3
    end

    it "should remove empty lines" do
      clean_text = 'clean'
      dirty_text = "#{clean_text}\n\n"
      create_parser.cleanup(dirty_text).should == clean_text
    end

    it "should replace newlines with <br/>" do
      clean_text = "<br/>clean"
      dirty_text = "\nclean"
      parser = Pidgin2Adium::HtmlLogParser.new(create_chat_file('dirty.html'), '')
      parser.cleanup(dirty_text).should == clean_text
    end

    it "should remove empty links" do
      clean_text = 'clean' * 2
      dirty_text = %Q{<a href="awesomelink">   </a>clean}
      dirty_text += %Q{<a href='awesomelink'></a>clean}
      create_parser.cleanup(dirty_text).should == clean_text
    end

    describe "with <span>s" do
      it "should remove font-family" do
        clean_text = 'clean'
        dirty_text = %Q{<span style='font-family: Helvetica;'>#{clean_text}</span>}
        create_parser.cleanup(dirty_text).should == clean_text
      end

      it "should remove font-size" do
        clean_text = 'clean'
        dirty_text = %Q{<span style="font-size: 6;">#{clean_text}</span>}
        create_parser.cleanup(dirty_text).should == clean_text
      end

      it "should remove background" do
        clean_text = 'clean'
        dirty_text = %Q{<span style="background: #00afaf;">#{clean_text}</span>}
        create_parser.cleanup(dirty_text).should == clean_text
      end

      it "should remove color=#00000" do
        clean_text = 'clean'
        dirty_text = %Q{<span style="color: #000000;">#{clean_text}</span>}
        create_parser.cleanup(dirty_text).should == clean_text
      end

      it "should not remove color != #00000" do
        dirty_text = %Q{<span style="color: #01ABcdef;">whatever</span>}
        create_parser.cleanup(dirty_text).should == dirty_text
      end

      it "should remove improperly-formatted colors" do
        clean_text = 'clean'
        dirty_text = %Q{<span style="color: #0;">#{clean_text}</span>}
        create_parser.cleanup(dirty_text).should == clean_text
      end

      it "should replace <em> with italic font-style" do
        text = 'whatever'
        dirty_text = "<em>#{text}</em>"
        clean_text = %Q{<span style="font-style: italic;">#{text}</span>}
        create_parser.cleanup(dirty_text).should == clean_text
      end

      it "shouldn't modify clean text" do
        create_parser.cleanup('clean').should == 'clean'
      end

      # This implicitly tests a lot of other things, but they've been tested
      # before this too.
      it "should remove a trailing space after style declaration and replace double quotes" do
        dirty_span_open = "<span style='color: #afaf00; font-size: 14pt; font-weight: bold; '>"
        # Replaced double quotes, removed space before ">"
        clean_span_open = '<span style="color: #afaf00;">'
        text = 'whatever'
        dirty_text = "#{dirty_span_open}#{text}</span>"
        clean_text = "#{clean_span_open}#{text}</span>"
        create_parser.cleanup(dirty_text).should == clean_text
      end
    end
  end

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
      @logfile = create_parser_for(path, 'Gabe B-W').parse
    end

    it "should return a LogFile instance" do
      @logfile.should be_instance_of(Pidgin2Adium::LogFile)
    end

    it "should return a LogFile with the correct number of chat_lines" do
      @logfile.chat_lines.size.should == 3
    end

    it "should return a LogFile with the correct message type" do
      @logfile.chat_lines.map(&:class).should == [Pidgin2Adium::XMLMessage] * 3
    end

    it "should return a LogFile with the correct data" do
      first_msg = @logfile.chat_lines[0]
      second_msg = @logfile.chat_lines[1]
      third_msg = @logfile.chat_lines[2]

      first_msg.sender_screen_name.should == "aolsystemmsg"
      first_msg.sender_alias.should == "AOL System Msg"
      # Use regex to ignore time zone
      first_msg.time.should =~ /^2008-01-15T07:14:45[-+]\d{2}:00$/
      # This fails due to balance_tags_c().
      good_body = %Q{Your screen name (otherSN) is now signed into AOL(R) Instant Messenger (TM) in 2 locations.} + " " +
        %Q{To sign off the other location(s), reply to this message with the number 1.} + " " +
        %Q{Click <a href="http://www.aim.com/password/routing.adp">here</a> for more information.}
      first_msg.body.should == good_body

      second_msg.sender_screen_name.should == "othersn"
      second_msg.sender_alias.should == "Gabe B-W"
      second_msg.time.should =~ /^2008-01-15T07:14:48[-+]\d{2}:00$/
      second_msg.body.should == "1"

      third_msg.sender_screen_name.should == "aolsystemmsg"
      third_msg.sender_alias.should == "AOL System Msg"
      # Use regex to ignore time zone
      third_msg.time.should =~ /^2008-01-15T07:14:48[-+]\d{2}:00$/
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
