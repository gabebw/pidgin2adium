require 'spec_helper'

describe Pidgin2Adium::BasicParser do
  describe "#parse" do
    it "returns false" do
      Pidgin2Adium::BasicParser.new(create_chat_file, '').parse.should be_false
    end
  end

  describe "#create_adium_time" do
    before do
      @bp = Pidgin2Adium::BasicParser.new(create_chat_file, '')
    end

    it "parses a first line time correctly" do
      first_line_time = "4/18/2007 11:02:00 AM"
      time = @bp.create_adium_time(first_line_time)
      time.should include '2007-04-18T11:02:00'
    end

    it "parses a normal time correctly" do
      normal_time = "2007-08-20 12:33:13"
      time = @bp.create_adium_time(normal_time)
      time.should include '2007-08-20T12:33:13'
    end

    it "parses a minimal time correctly" do
      minimal_time = "04:22:05 AM"
      path = create_chat_file('minimal.html') do |b|
        b.first_line :time => "1/15/2008 7:14:45 AM"
      end
      parser = Pidgin2Adium::BasicParser.new(path, '')
      time = parser.create_adium_time(minimal_time)
      time.should include '2008-01-15T04:22:05'
    end

    it "parses a minimal time without AM/PM correctly" do
      minimal_time_without_ampm = "04:22:05"
      path = create_chat_file('minimal.html') do |b|
        b.first_line :time => "1/15/2008 7:14:45 AM"
      end
      parser = Pidgin2Adium::BasicParser.new(path, '')
      time = parser.create_adium_time(minimal_time_without_ampm)
      time.should include '2008-01-15T04:22:05'
    end

    it "returns nil for an invalid time" do
      invalid_time = "Hammer time!"
      time = @bp.create_adium_time(invalid_time)
      time.should be_nil
    end
  end

  describe "#pre_parse!" do
    it "raises an error for an invalid first line" do
      path = File.join(@current_dir, "logfiles", "invalid-first-line.txt")
      bp =  Pidgin2Adium::BasicParser.new(path, '')
      lambda do
        bp.pre_parse!()
      end.should raise_error(Pidgin2Adium::InvalidFirstLineError)
    end

    it "returns true when everything can be parsed" do
      path = create_chat_file('blah.html') do |b|
        b.first_line
      end
      parser = Pidgin2Adium::BasicParser.new(path, '')
      parser.pre_parse!.should be_true
    end

    describe "correctly setting variables" do
      before do
        path = create_chat_file('blah.html') do |b|
          b.first_line :from => 'othersn', :to => 'aolsystemmsg',
            :time => '1/15/2008 7:14:45 AM', :service => 'aim'
        end

        @bp =  Pidgin2Adium::BasicParser.new(path, '')
        @bp.pre_parse!
      end

      it "correctly sets @service" do
        @bp.instance_variable_get('@service').should == 'aim'
      end

      it "correctly sets user_SN" do
        @bp.instance_variable_get('@user_SN').should == 'othersn'
      end

      it "correctly sets partner_SN" do
        @bp.instance_variable_get('@partner_SN').should == 'aolsystemmsg'
      end

      it "correctly sets basic_time_info" do
        @bp.instance_variable_get('@basic_time_info').should == {:year=>2008, :mon=>1, :mday=>15}
      end

      it "correctly sets adium_chat_time_start" do
        @bp.instance_variable_get('@adium_chat_time_start').should == '2008-01-15T07:14:45EST'
      end
    end
  end

  describe "#get_sender_by_alias" do
    before do
      path = create_chat_file('sender.txt') do |b|
        b.first_line :from => "awesome SN", :to => "BUDDY_PERSON"
        b.message :from_alias => "Gabe B-W"
        b.message :from_alias => "Leola Farber III"
      end
      @my_alias = "Gabe B-W"
      @my_SN =  "awesomesn" # normalized from "awesome SN"

      @partner_alias = "Leola Farber III"
      @partner_SN = "BUDDY_PERSON" # not normalized
      @bp = Pidgin2Adium::BasicParser.new(path, 'Gabe B-W')
    end

    it "returns my SN when passed my alias" do
      @bp.get_sender_by_alias(@my_alias).should == @my_SN
    end

    it "returns my SN when passed my alias with an action" do
      @bp.get_sender_by_alias("***#{@my_alias}").should == @my_SN
    end

    it "returns partner's SN when passed partner's alias" do
      @bp.get_sender_by_alias(@partner_alias).should == @partner_SN
    end
  end

  describe "#create_msg" do
    before do
      body = "Your screen name (otherSN) is now signed into " +
        "AOL(R) Instant Messenger (TM) in 2 locations. " +
        "To sign off the other location(s), reply to this message " + "with the number 1. Click " +
        "<a href='http://www.aim.com/password/routing.adp'>here</a> " +
        "for more information."
      @matches = ['2008-01-15T07.14.45-05:00', # time
                  'AOL System Msg', # alias
                  nil, # not an auto-reply
                  body # message body
                 ]
      @auto_reply_matches = @matches.dup
      @auto_reply_matches[2] = '<AUTO-REPLY>'

      @bp = Pidgin2Adium::BasicParser.new(create_chat_file, "Gabe B-W")
    end


    it "returns XMLMessage class for a normal message" do
      @bp.create_msg(@matches).should
        be_instance_of(Pidgin2Adium::XMLMessage)
    end

    it "returns AutoReplyMessage class for an auto reply" do
      @bp.create_msg(@auto_reply_matches).should
        be_instance_of(Pidgin2Adium::AutoReplyMessage)
    end

    it "returns nil if the time is nil" do
      @matches[0] = nil
      @bp.create_msg(@matches).should be_nil
    end
  end

  describe "#create_status_or_event_msg" do
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
      @libpurple_event_msg = "Starting transfer of cute kitties.jpg from Gabe B-W"
      @event_msg =  "You missed 8 messages from Gabe B-W because they were too large"
      @event_type = 'chat-error'

      @ignored_event_msg = "Gabe B-W is now known as gbw.<br/>"

      @bp = Pidgin2Adium::BasicParser.new(create_chat_file, @alias)
    end

    it "maps statuses correctly" do
      @status_map.each do |message, status|
        return_value = @bp.create_status_or_event_msg([@time,
                                                     message])
        return_value.should be_instance_of(Pidgin2Adium::StatusMessage)
        return_value.status.should == status
      end
    end

    it "maps libpurple events correctly" do
      return_val = @bp.create_status_or_event_msg([@time,
                                                  @libpurple_event_msg])
      return_val.should be_instance_of(Pidgin2Adium::Event)
      return_val.event_type.should == 'libpurpleEvent'
    end

    it "maps non-libpurple events correctly" do
      return_val = @bp.create_status_or_event_msg([@time,
                                                  @event_msg])
      return_val.should be_instance_of(Pidgin2Adium::Event)
      return_val.event_type.should == @event_type
    end

    it "returns nil for ignored events" do
      return_val = @bp.create_status_or_event_msg([@time,
                                                  @ignored_event_msg])
      return_val.should be_nil
    end
  end
end

describe Pidgin2Adium::BasicParser, "#try_to_parse_time" do
  let(:parser) { Pidgin2Adium::BasicParser.new(create_chat_file, '') }

  it 'parses "%m/%d/%Y %I:%M:%S %P"' do
    time = '01/22/2008 03:01:45 PM'
    parseable_time = '2008-01-22 03:01:45 PM'
    parser.try_to_parse_time(time).should == Time.parse(parseable_time)
  end

  it 'parses "%Y-%m-%d %H:%M:%S"' do
    time = '2008-01-22 23:08:24'
    parser.try_to_parse_time(time).should == Time.parse(time)
  end

  it 'parses "%Y/%m/%d %H:%M:%S"' do
    time = '2008/01/22 04:01:45'
    parser.try_to_parse_time(time).should == Time.parse(time)
  end

  it 'parses "%Y-%m-%d %H:%M:%S"' do
    time = '2008-01-22 04:01:45'
    parser.try_to_parse_time(time).should == Time.parse(time)
  end

  it 'parses "%a %d %b %Y %H:%M:%S %p %Z", ignoring time zones' do
    time = "Sat 18 Apr 2009 10:43:35 AM PDT"
    time_without_zone = time.sub('PDT', '')
    parsed_time = Time.parse(time_without_zone)
    parsed_time.hour.should == 10
    parser.try_to_parse_time(time).should == parsed_time
  end

  it 'parses "%a %b %d %H:%M:%S %Y"' do
    time = "Wed May 24 19:00:33 2006"
    parser.try_to_parse_time(time).should == Time.parse(time)
  end
end

describe Pidgin2Adium::BasicParser, "#is_minimal_time?" do
  let(:parser) { Pidgin2Adium::BasicParser.new(create_chat_file, '') }

  it 'returns true for a time like 03:04:08' do
    parser.is_minimal_time?('03:04:08').should be
  end

  it 'returns true for a time like 03:04:08 AM' do
    parser.is_minimal_time?('03:04:08 AM').should be
  end

  it 'returns true for a time like 03:04:08 PM' do
    parser.is_minimal_time?('03:04:08 PM').should be
  end

  it 'strips space before matching' do
    parser.is_minimal_time?('  03:04:08  ').should be
  end

  it 'returns false for other times' do
    parser.is_minimal_time?('2006-08-02 03:04:08').should_not be
  end
end

describe Pidgin2Adium::BasicParser, "#strptime" do
  it 'parses a time string according to a given format' do
    time_string = '2008-02-25 03:04:08'
    result = create_parser.strptime(time_string, '%Y-%m-%d %H:%M:%S')
    result.should == Time.parse(time_string)
  end

  it 'fills in missing times with values from the first line' do
    parser = create_parser do |b|
      b.first_line :time => "2007-04-17 12:33:13"
    end
    result = parser.strptime('03:04:08', '%H:%M:%S')
    result.year.should == 2007
    result.day.should == 17
    result.month.should == 4
  end

  it 'returns nil if the format does not match' do
    create_parser.strptime('03', '%H:%M:%S').should be_nil
  end

  def create_parser(&block)
    Pidgin2Adium::BasicParser.new(create_chat_file(&block), '')
  end
end
