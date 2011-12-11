require 'spec_helper'

describe Pidgin2Adium::TimeConverter do
  describe "#to_adium" do
    it "converts a first-line time to Adium format" do
      first_line_time = "4/18/2007 11:02:00 AM"
      time = Pidgin2Adium::TimeConverter.new(first_line_time).to_adium
      time.should == '2007-04-18T11:02:00+00:00'
    end

    it "returns nil if the time is nil" do
      Pidgin2Adium::TimeConverter.new(nil).to_adium.should be_nil
    end

    it "converts a normal time to Adium format" do
      normal_time = "2007-08-20 12:33:13"
      time = Pidgin2Adium::TimeConverter.new(normal_time).to_adium
      time.should == '2007-08-20T12:33:13+00:00'
    end

    it "converts a 12-hour minimal time to Adium format" do
      twelve_hour_minimal_time = "04:22:05 AM"
      time = Pidgin2Adium::TimeConverter.new(twelve_hour_minimal_time, :year => '2008', :month => '1', :day => '15').to_adium
      time.should == '2008-01-15T04:22:05+00:00'
    end

    it "converts a 24-hour minimal time to Adium format" do
      twenty_four_hour_minimal_time = "04:22:05"
      time = Pidgin2Adium::TimeConverter.new(twenty_four_hour_minimal_time, :year => '2008', :month => '1', :day => '15').to_adium
      time.should == '2008-01-15T04:22:05+00:00'
    end

    it "returns nil for an invalid time" do
      Pidgin2Adium::TimeConverter.new('Hammer time!').to_adium.should be_nil
    end
  end
end
