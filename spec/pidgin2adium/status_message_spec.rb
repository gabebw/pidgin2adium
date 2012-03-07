require 'spec_helper'

describe Pidgin2Adium::StatusMessage, '#to_s' do
  it 'has the correct sender' do
    sender = 'bob'
    result = create_status_message(:sender => sender).to_s
    result.should include %(sender="#{sender}")
  end

  it 'has the correct time' do
    time = Time.now.strftime('%H:%M:%S')
    result = create_status_message(:time => time).to_s
    result.should include %(time="#{time}")
  end

  it 'has the correct alias' do
    buddy_alias = 'jane_alias'
    result = create_status_message(:buddy_alias => buddy_alias).to_s
    result.should include %(alias="#{buddy_alias}")
  end

  it 'has the correct status' do
    status = 'status'
    result = create_status_message(:status => status).to_s
    result.should include %(type="#{status}")
  end

  it 'is a status tag' do
    create_status_message.to_s.should =~ /^<status/
  end

  it 'ends in a newline' do
    create_status_message.to_s.should =~ /\n$/
  end

  def create_status_message(opts = {})
    opts[:sender] ||= 'jim_sender'
    opts[:time] ||= Time.now.strftime('%H:%M:%S')
    opts[:buddy_alias] ||= 'jane_alias'
    opts[:status] ||= 'status'

    Pidgin2Adium::StatusMessage.new(opts[:sender], opts[:time], opts[:buddy_alias], opts[:status])
  end
end
