require 'spec_helper'

describe Pidgin2Adium::BasicParser do
  describe "#pre_parse" do
    it "returns false for an empty file" do
      path = File.join(@spec_directory, "logfiles", "invalid-first-line.txt")
      bp =  Pidgin2Adium::BasicParser.new(path, '')
      bp.pre_parse.should be_false
    end

    it "returns true when everything can be parsed" do
      path = create_chat_file('blah.html') do |b|
        b.first_line
      end
      parser = Pidgin2Adium::BasicParser.new(path, '')
      parser.pre_parse.should be_true
    end
  end

  describe "#sender_from_alias" do
    before do
      path = create_chat_file('sender.txt') do |b|
        b.first_line :from => "awesome SN", :to => "BUDDY_PERSON"
        b.message :from_alias => "Gabe B-W"
        b.message :from_alias => "Jack"
      end

      @bp = Pidgin2Adium::BasicParser.new(path, 'Gabe B-W')
      @bp.pre_parse
    end

    it "returns my SN when passed my alias" do
      @bp.sender_from_alias("Gabe B-W").should == "awesomesn"
    end

    it "returns my SN when passed my alias with an action" do
      @bp.sender_from_alias("***Gabe B-W").should == "awesomesn"
    end

    it "returns partner's SN when passed partner's alias" do
      @bp.sender_from_alias("Jack").should == "BUDDY_PERSON"
    end
  end

  describe "#create_message" do
    before do
      body = "Your screen name (otherSN) is now signed into " +
        "AOL(R) Instant Messenger (TM) in 2 locations. " +
        "To sign off the other location(s), reply to this message " + "with the number 1. Click " +
        "<a href='http://www.aim.com/password/routing.adp'>here</a> " +
        "for more information."
      @matches = ['2008-01-15T07.14.45-05:00', # time
                  'AOL System message', # alias
                  nil, # not an auto-reply
                  body # message body
                 ]
      @auto_reply_matches = @matches.dup
      @auto_reply_matches[2] = '<AUTO-REPLY>'

      @bp = Pidgin2Adium::BasicParser.new(create_chat_file, "Gabe B-W")
      @bp.pre_parse
    end

    it "returns XMLMessage class for a normal message" do
      @bp.create_message(@matches).should
        be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "returns AutoReplyMessage class for an auto reply" do
      @bp.create_message(@auto_reply_matches).should
        be_instance_of(Pidgin2Adium::AutoReplyMessage)
    end

    it "returns nil if the time is nil" do
      @matches[0] = nil
      @bp.create_message(@matches).should be_nil
    end
  end

  describe "#create_status_or_event_message" do
    before do
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
      @libpurple_event_message = "Starting transfer of cute kitties.jpg from Gabe B-W"
      @event_message =  "You missed 8 messages from Gabe B-W because they were too large"
      @event_type = 'chat-error'

      @ignored_event_message = "Gabe B-W is now known as gbw.<br/>"

      @bp = Pidgin2Adium::BasicParser.new(create_chat_file, @alias)
      @bp.pre_parse
    end

    it "maps statuses correctly" do
      @status_map.each do |message, status|
        return_value = @bp.create_status_or_event_message([@time,
                                                     message])
        return_value.should be_instance_of(Pidgin2Adium::StatusMessage)
        return_value.status.should == status
      end
    end

    it "maps libpurple events correctly" do
      return_val = @bp.create_status_or_event_message([@time,
                                                  @libpurple_event_message])
      return_val.should be_instance_of(Pidgin2Adium::Event)
      return_val.event_type.should == 'libpurpleEvent'
    end

    it "maps non-libpurple events correctly" do
      return_val = @bp.create_status_or_event_message([@time,
                                                  @event_message])
      return_val.should be_instance_of(Pidgin2Adium::Event)
      return_val.event_type.should == @event_type
    end

    it "returns nil for ignored events" do
      return_val = @bp.create_status_or_event_message([@time,
                                                  @ignored_event_message])
      return_val.should be_nil
    end
  end
end
