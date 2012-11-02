describe Pidgin2Adium::Event, '#to_s' do
  it 'has the correct sender screen name' do
    sender_screen_name = 'bob'
    result = create_event(:sender_screen_name => sender_screen_name).to_s
    result.should include %(sender="#{sender_screen_name}")
  end

  it 'has the correct time' do
    time = Time.now
    formatted_time = time.xmlschema
    result = create_event(:time => time).to_s
    result.should include %(time="#{formatted_time}")
  end

  it 'has the correct alias' do
    sender_alias = 'jane_alias'
    result = create_event(:sender_alias => sender_alias).to_s
    result.should include %(alias="#{sender_alias}")
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
    opts[:sender_screen_name] ||= 'jim_sender'
    opts[:time] ||= Time.now
    opts[:sender_alias] ||= 'jane_alias'
    opts[:body] ||= 'body'
    opts[:event_type] ||= 'libPurpleEvent'

    Pidgin2Adium::Event.new(opts[:sender_screen_name], opts[:time], opts[:sender_alias], opts[:body], opts[:event_type])
  end
end
