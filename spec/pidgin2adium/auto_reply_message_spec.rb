require 'spec_helper'

describe Pidgin2Adium::AutoReplyMessage, '#to_s' do
  let(:sender_screen_name) { 'jim_sender' }
  let(:time) { Time.now }
  let(:sender_alias) { 'jane_alias' }
  let(:body) { 'body' }

  let(:auto_reply_message) do
    Pidgin2Adium::AutoReplyMessage.new(sender_screen_name, time, sender_alias, body)
  end

  it 'has the correct sender_screen_name' do
    auto_reply_message.to_s.should include %(sender="#{sender_screen_name}")
  end

  it 'has the correct alias' do
    auto_reply_message.to_s.should include %(alias="#{sender_alias}")
  end

  it 'has the correct time' do
    formatted_time = time.strftime('%Y-%m-%dT%H:%M:%S%Z')
    result = auto_reply_message.to_s
    result.should include %(time="#{formatted_time}")
  end

  it 'has the correct body' do
    styled_body = %(<div><span style="font-family: Helvetica; font-size: 12pt;">#{body}</span></div>)
    auto_reply_message.to_s.should include styled_body
  end

  it 'has the auto attribute set to true' do
    auto_reply_message.to_s.should include 'auto="true"'
  end
end
