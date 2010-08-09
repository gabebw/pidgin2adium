require 'spec_helper'
require 'active_support' # for Time.zone_offset

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
      time.should == [nil] * 8
    end
  end
end
