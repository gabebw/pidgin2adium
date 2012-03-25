require 'spec_helper'

describe Pidgin2Adium::Metadata do
  context '#service' do
    it 'returns the correct service' do
      metadata = Pidgin2Adium::Metadata.new(:service => 'aim')
      metadata.service.should == 'aim'
    end
  end

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

  context '#start_time' do
    it 'returns the start time' do
      start_time = Time.now
      metadata = Pidgin2Adium::Metadata.new(:start_time => start_time)
      metadata.start_time.should == start_time
    end
  end

  context '#invalid?' do
    it 'is false when all attributes are provided' do
      metadata = Pidgin2Adium::Metadata.new({ :service => '',
        :sender_screen_name => '',
        :receiver_screen_name => '',
        :start_time => '' })
      metadata.should_not be_invalid
    end

    [:sender_screen_name, :receiver_screen_name, :service, :start_time].each do |attribute|
      it 'is true when #{attribute} cannot be detected' do
        Pidgin2Adium::Metadata.new(attribute => nil).should be_invalid
      end
    end
  end
end
