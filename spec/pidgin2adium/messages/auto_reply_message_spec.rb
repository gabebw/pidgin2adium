describe Pidgin2Adium::AutoReplyMessage, '#to_s' do
  it 'has the correct sender_screen_name' do
    expect(auto_reply_message(sender_screen_name: "hello").to_s).to include 'sender="hello"'
  end

  it 'has the correct alias' do
    expect(auto_reply_message(sender_alias: "garner").to_s).to include 'alias="garner"'
  end

  it 'has the correct time' do
    time = Time.now
    formatted_time = time.xmlschema
    expect(auto_reply_message(time: time).to_s).to include %(time="#{formatted_time}")
  end

  it 'has the correct body' do
    body = "hello"
    styled_body = %(<div><span style="font-family: Helvetica; font-size: 12pt;">#{body}</span></div>)
    expect(auto_reply_message(body: body).to_s).to include styled_body
  end

  it 'has the auto attribute set to true' do
    expect(auto_reply_message.to_s).to include 'auto="true"'
  end

  def auto_reply_message(options = {})
    options = default_options.merge(options)
    Pidgin2Adium::AutoReplyMessage.new(options[:sender_screen_name],
      options[:time], options[:sender_alias], options[:body])
  end

  def default_options
    {
      sender_screen_name: 'jim_sender',
      time: Time.now,
      sender_alias: 'jim alias',
      body: 'body'
    }
  end
end
