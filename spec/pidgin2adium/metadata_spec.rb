require 'spec_helper'

describe Pidgin2Adium::Metadata do
  context '#sender_screen_name' do
    it "returns the sender's normalized screen name" do
      metadata = Pidgin2Adium::Metadata.new(:sender_screen_name => 'JIM BOB')
      metadata.sender_screen_name.should == 'jimbob'
    end
  end

  context '#receiver_screen_name' do
    it "returns the receiver's screen name" do
      metadata = Pidgin2Adium::Metadata.new(:receiver_screen_name => 'lady anne')
      metadata.receiver_screen_name.should == 'lady anne'
    end
  end

  context '#start_month' do
    it 'returns the start month' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(:start_time => start_time)
      metadata.start_month.should == start_time.mon
    end
  end

  context '#start_year' do
    it 'returns the start year' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(:start_time => start_time)
      metadata.start_year.should == start_time.year
    end
  end

  context '#start_mday' do
    it 'returns the start mday' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(:start_time => start_time)
      metadata.start_mday.should == start_time.mday
    end
  end

  context '#valid?' do
    it 'is true when all attributes are provided' do
      metadata = Pidgin2Adium::Metadata.new({ :sender_screen_name => '',
        :receiver_screen_name => '',
        :start_time => '' })
      metadata.should be_valid
    end

    [:sender_screen_name, :receiver_screen_name, :start_time].each do |attribute|
      it "is false when #{attribute} cannot be detected" do
        Pidgin2Adium::Metadata.new(attribute => nil).should_not be_valid
      end
    end
  end
end
