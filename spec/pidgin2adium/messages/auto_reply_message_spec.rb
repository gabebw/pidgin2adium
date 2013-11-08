describe Pidgin2Adium::AutoReplyMessage, '#to_s' do
  it 'has the correct my_screen_name' do
    auto_reply_message(my_screen_name: "hello").to_s.should include 'sender="hello"'
  end

  it 'has the correct alias' do
    auto_reply_message(my_alias: "garner").to_s.should
      include 'alias="garner"'
  end

  it 'has the correct time' do
    time = Time.now
    formatted_time = time.xmlschema
    auto_reply_message(time: time).to_s.should include
      %(time="#{formatted_time}")
  end

  it 'has the correct body' do
    body = "hello"
    styled_body = %(<div><span style="font-family: Helvetica; font-size: 12pt;">#{body}</span></div>)
    auto_reply_message(body: body).to_s.should include styled_body
  end

  it 'has the auto attribute set to true' do
    auto_reply_message.to_s.should include 'auto="true"'
  end


  def auto_reply_message(options = {})
    options = default_options.merge(options)
    Pidgin2Adium::AutoReplyMessage.new(options[:my_screen_name],
      options[:time], options[:my_alias], options[:body])
  end

  def default_options
    {
      my_screen_name: 'jim_sender',
      time: Time.now,
      my_alias: 'jim alias',
      body: 'body'
    }
  end
end
