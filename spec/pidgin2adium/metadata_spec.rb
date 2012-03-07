require 'spec_helper'

describe Pidgin2Adium::Metadata do
  context '#service' do
    it 'returns the correct service' do
      path = create_chat_file('log.html') do |b|
        b.first_line :service => 'aim'
      end
      metadata = Pidgin2Adium::Metadata.new(first_line_of(path))
      metadata.service.should == 'aim'
    end
  end

  context '#sender_screen_name' do
    it "returns the sender's normalized screen name" do
      path = create_chat_file('log.html') do |b|
        b.first_line :from => 'JIM BOB'
      end
      metadata = Pidgin2Adium::Metadata.new(first_line_of(path))
      metadata.sender_screen_name.should == 'jimbob'
    end
  end

  context '#receiver_screen_name' do
    it "returns the receiver's screen name" do
      path = create_chat_file('log.html') do |b|
        b.first_line :to => 'lady anne'
      end
      metadata = Pidgin2Adium::Metadata.new(first_line_of(path))
      metadata.receiver_screen_name.should == 'lady anne'
    end
  end

  context '#start_time' do
    it 'returns the start time' do
      time_string = '2008-04-01 22:36:06'
      path = create_chat_file('log.html') do |b|
        b.first_line :time => time_string
      end
      metadata = Pidgin2Adium::Metadata.new(first_line_of(path))
      metadata.start_time.year.should == 2008
      metadata.start_time.mon.should == 4
      metadata.start_time.mday.should == 1
      metadata.start_time.hour.should == 22
      metadata.start_time.min.should == 36
      metadata.start_time.sec.should == 6
    end

    it 'can detect peculiar times' do
      time_string = "1/15/2008 7:14:45 AM"
      path = create_chat_file('log.html') do |b|
        b.first_line :time => time_string
      end
      metadata = Pidgin2Adium::Metadata.new(first_line_of(path))
      metadata.start_time.year.should == 2008
      metadata.start_time.mon.should == 1
      metadata.start_time.mday.should == 15
      metadata.start_time.hour.should == 7
      metadata.start_time.min.should == 14
      metadata.start_time.sec.should == 45
    end
  end

  context '#invalid?' do
    it 'is false when all data can be parsed' do
      metadata = Pidgin2Adium::Metadata.new(first_line_of(create_chat_file))
      metadata.should_not be_invalid
    end

    it 'is true when initialized with an empty string' do
      metadata = Pidgin2Adium::Metadata.new('')
      metadata.should be_invalid
    end

    it 'is true when initialized with nil' do
      metadata = Pidgin2Adium::Metadata.new(nil)
      metadata.should be_invalid
    end

    [:sender_screen_name, :receiver_screen_name, :service, :start_time].each do |attribute|
      it 'is true when #{attribute} cannot be detected' do
        metadata = Pidgin2Adium::Metadata.new(first_line_of(create_chat_file))
        metadata.stubs(attribute => nil)
        metadata.should be_invalid
      end
    end
  end

  def first_line_of(path)
    File.readlines(path).first
  end
end
