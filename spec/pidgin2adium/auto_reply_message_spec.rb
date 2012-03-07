require 'spec_helper'

describe Pidgin2Adium::AutoReplyMessage, '#to_s' do
  let(:sender) { 'jim_sender' }
  let(:time) { Time.now.strftime('%H:%M:%S') }
  let(:buddy_alias) { 'jane_alias' }
  let(:body) { 'body' }

  let(:auto_reply_message) do
    Pidgin2Adium::AutoReplyMessage.new(sender, time, buddy_alias, body)
  end

  it 'has the correct sender' do
    auto_reply_message.to_s.should include %(sender="#{sender}")
  end

  it 'has the correct alias' do
    auto_reply_message.to_s.should include %(alias="#{buddy_alias}")
  end

  it 'has the correct body' do
    styled_body = %(<div><span style="font-family: Helvetica; font-size: 12pt;">#{body}</span></div>)
    auto_reply_message.to_s.should include styled_body
  end

  it 'has the auto attribute set to true' do
    auto_reply_message.to_s.should include 'auto="true"'
  end
end
