require 'spec_helper'

describe Pidgin2Adium::Event, '#to_s' do
  it 'has the correct sender' do
    sender = 'bob'
    result = create_event(:sender => sender).to_s
    result.should include %(sender="#{sender}")
  end

  it 'has the correct time' do
    time = Time.now.strftime('%H:%M:%S')
    result = create_event(:time => time).to_s
    result.should include %(time="#{time}")
  end

  it 'has the correct alias' do
    buddy_alias = 'jane_alias'
    result = create_event(:buddy_alias => buddy_alias).to_s
    result.should include %(alias="#{buddy_alias}")
  end

  it 'has the correct body' do
    body = 'body'
    styled_body = %(<div><span style="font-family: Helvetica; font-size: 12pt;">#{body}</span></div>)
    result = create_event(:body => body).to_s
    result.should include styled_body
  end

  it 'is an event tag' do
    create_event.to_s.should =~ /^<event/
  end

  def create_event(opts = {})
    opts[:sender] ||= 'jim_sender'
    opts[:time] ||= Time.now.strftime('%H:%M:%S')
    opts[:buddy_alias] ||= 'jane_alias'
    opts[:body] ||= 'body'
    opts[:event_type] ||= 'libPurpleEvent'

    Pidgin2Adium::Event.new(opts[:sender], opts[:time], opts[:buddy_alias], opts[:body], opts[:event_type])
  end
end
