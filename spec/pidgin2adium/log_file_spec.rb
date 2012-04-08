require 'spec_helper'

describe "LogFile" do
  before do
    @sender_screen_name = "gabebw"
    @user_alias = "Gabe B-W"

    @receiver_screen_name = "matz"
    @partner_alias = "Yukihiro Matsumoto"

    @start_time = "2010-08-10T22:55:07-0500"
    times = [@start_time,
             "2010-08-10T22:55:12-0500",
             "2010-08-10T22:55:17-0500",
             "2010-08-10T22:55:22-0500"].map { |string| Time.parse(string) }

    message_1 = Pidgin2Adium::XMLMessage.new(@sender_screen_name, times[0],
                                             @user_alias, "Hello!")
    message_2 = Pidgin2Adium::StatusMessage.new(@receiver_screen_name, times[1],
                                                @partner_alias, "Matz has gone away")

    message_3 = Pidgin2Adium::Event.new(@sender_screen_name, times[2], @user_alias,
                                        "gabebw logged in.", 'online')

    message_4 = Pidgin2Adium::AutoReplyMessage.new(@receiver_screen_name, times[3],
                                                   @partner_alias,
                                                   "This is an away message")

    @messages = [message_1, message_2, message_3, message_4]
    @logfile = Pidgin2Adium::LogFile.new(@messages)
  end

  describe "#to_s" do
    it "should return the correct string" do
      @logfile.to_s.should == @messages.map(&:to_s).join
    end
  end


  describe "enumerable methods" do
    it "should include Enumerable" do
      Pidgin2Adium::LogFile.included_modules.include?(Enumerable).should be_true
    end

    describe "#each_with_index" do
      it "yields the correct messages, in order" do
        @logfile.each_with_index do |msg, n|
          msg.should == @messages[n]
        end
      end
    end

    describe "#max" do
      it "returns the most recent message" do
        @logfile.max.should == @messages.last
      end
    end

    describe "#min" do
      it "returns the oldest message" do
        @logfile.min.should == @messages.first
      end
    end
  end
end
