require 'spec_helper'
require 'time' # for Time.zone_offset

describe "BasicParser" do
  it "should include Pidgin2Adium" do
    Pidgin2Adium::BasicParser.included_modules.include?(Pidgin2Adium).should be_true
  end

  # can't test BasicParser#parse because parse() can't be called from a
  # BasicParser instance.

  describe "#get_time_zone_offset" do
    context "with no timezone available" do
      it "should return the local time zone" do
        tz_offset = sprintf('%+03d00',
                            Time.zone_offset(Time.now.zone) / 3600)
        bp = Pidgin2Adium::BasicParser.new(@text_logfile_path,
                                           @aliases)
        bp.get_time_zone_offset.should == tz_offset
      end
    end

    context "with a time zone available" do
      it "should return the logfiles's time zone" do
        bp = Pidgin2Adium::BasicParser.new(@html_logfile_path,
                                           @aliases)
        bp.get_time_zone_offset.should == "-0500"
      end
    end
  end

  describe "#create_adium_time" do
    before(:each) do
      @first_line_time = "4/18/2007 11:02:00 AM"
      @time = "2007-08-20 12:33:13"
      @minimal_time = "04:22:05 AM"
      @minimal_time_2 = "04:22:05"
      @invalid_time = "Hammer time!"

      @bp = Pidgin2Adium::BasicParser.new(@html_logfile_path,
                                          @aliases)
    end

    it "should parse a first line time correctly" do
      time = @bp.create_adium_time(@first_line_time, true)
      time.should == "2007-04-18T11.02.00-0500"
    end

    it "should parse a normal time correctly" do
      time = @bp.create_adium_time(@time)
      time.should == "2007-08-20T12:33:13-0500"
    end

    it "should parse a minimal time correctly" do
      time = @bp.create_adium_time(@minimal_time)
      time.should == "2008-01-15T04:22:05-0500"
    end

    it "should parse a minimal time without AM/PM correctly" do
      time = @bp.create_adium_time(@minimal_time_2)
      time.should == "2008-01-15T04:22:05-0500"
    end

    it "should return an array of nils for an invalid time" do
      time = @bp.create_adium_time(@invalid_time)
      time.should be_nil
    end
  end

  describe "#pre_parse" do
    it "should raise an error for an invalid first line" do
      bp =  Pidgin2Adium::BasicParser.new(
              File.join(@current_dir,
                        "logfiles",
                        "invalid-first-line.txt"),
              @aliases)
      lambda do
        bp.pre_parse()
      end.should raise_error(Pidgin2Adium::InvalidFirstLineError)
    end

    it "should return correct info for an valid first line" do
      bp =  Pidgin2Adium::BasicParser.new(@html_logfile_path,
                                          @aliases)
      results = bp.pre_parse()
      results.should be_instance_of(Array)
      results.should == ['aim', # service
                         'othersn', # my SN
                         'aolsystemmsg', # other person's SN
                         [2008, 1, 15], # basic time info
                         '2008-01-15T07.14.45-0500' # chat start time
                        ]
    end
  end

  describe "#get_sender_by_alias" do
    before(:each) do
      @my_alias = "Gabe B-W"
      @my_SN =  "awesomesn" # normalized from "awesome SN"

      @partner_alias = "Leola Farber III"
      @partner_SN = "BUDDY_PERSON" # not normalized
      # Use text logfile since it has aliases set up.
      @bp = Pidgin2Adium::BasicParser.new(@text_logfile_path,
                                          @my_alias)
    end

    it "should return my SN when passed my alias" do
      @bp.get_sender_by_alias(@my_alias).should == @my_SN
    end

    it "should return my SN when passed my alias with an action" do
      @bp.get_sender_by_alias("***#{@my_alias}").should == @my_SN
    end

    it "should return partner's SN when passed partner's alias" do
      @bp.get_sender_by_alias(@partner_alias).should == @partner_SN
    end
  end

  describe "#create_msg" do
    before(:each) do
      body = "Your screen name (otherSN) is now signed into " +
        "AOL(R) Instant Messenger (TM) in 2 locations. " +
        "To sign off the other location(s), reply to this message " + "with the number 1. Click " +
        "<a href='http://www.aim.com/password/routing.adp'>here</a> " +
        "for more information."
      @matches = ['2008-01-15T07.14.45-0500', # time
                  'AOL System Msg', # alias
                  nil, # not an auto-reply
                  body # message body
                 ]
      @auto_reply_matches = @matches.dup
      @auto_reply_matches[2] = '<AUTO-REPLY>'

      @bp = Pidgin2Adium::BasicParser.new(@text_logfile_path,
                                          "Gabe B-W")
    end


    it "should return XMLMessage class for a normal message" do
      @bp.create_msg(@matches).should
        be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "should return AutoReplyMessage class for an auto reply" do
      @bp.create_msg(@auto_reply_matches).should
        be_instance_of(Pidgin2Adium::AutoReplyMessage)
    end

    it "should return nil if the time is nil" do
      @matches[0] = nil
      @bp.create_msg(@matches).should be_nil
    end
  end

  describe "#create_status_or_event_msg" do
    before(:each) do
      # not yet converted to Adium format
      @time = "2007-08-20 12:33:13"
      @alias = "Gabe B-W"
      @status_map = {
        "#{@alias} logged in." => 'online',
        "#{@alias} logged out." => 'offline',
        "#{@alias} has signed on." => 'online',
        "#{@alias} has signed off." => 'offline',
        "#{@alias} has gone away." => 'away',
        "#{@alias} is no longer away." => 'available',
        "#{@alias} has become idle." => 'idle',
        "#{@alias} is no longer idle." => 'available'
      }

      # Small subset of all events
      @libpurple_event_msg = "Starting transfer of cute kitties.jpg from Gabe B-W"
      @event_msg =  "You missed 8 messages from Gabe B-W because they were too large"
      @event_type = 'chat-error'

      @ignored_event_msg = "Gabe B-W is now known as gbw.<br/>"

      @bp = Pidgin2Adium::BasicParser.new(@html_logfile_path,
                                          @alias)
    end

    it "should map statuses correctly" do
      @status_map.each do |message, status|
        return_value = @bp.create_status_or_event_msg([@time,
                                                     message])
        return_value.should be_instance_of(Pidgin2Adium::StatusMessage)
        return_value.status.should == status
      end
    end

    it "should map libpurple events correctly" do
      return_val = @bp.create_status_or_event_msg([@time,
                                                  @libpurple_event_msg])
      return_val.should be_instance_of(Pidgin2Adium::Event)
      return_val.event_type.should == 'libpurpleEvent'
    end

    it "should map non-libpurple events correctly" do
      return_val = @bp.create_status_or_event_msg([@time,
                                                  @event_msg])
      return_val.should be_instance_of(Pidgin2Adium::Event)
      return_val.event_type.should == @event_type
    end

    it "should return nil for ignored events" do
      return_val = @bp.create_status_or_event_msg([@time,
                                                  @ignored_event_msg])
      return_val.should be_nil
    end
  end
end
