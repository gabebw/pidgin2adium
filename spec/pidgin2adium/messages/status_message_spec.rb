describe Pidgin2Adium::StatusMessage, '#to_s' do
  it 'has the correct sender' do
    sender_screen_name = 'bob'
    result = create_status_message(sender_screen_name: sender_screen_name).to_s
    result.should include %(sender="#{sender_screen_name}")
  end

  it 'has the correct time' do
    time = Time.now
    formatted_time = time.xmlschema
    result = create_status_message(time: time).to_s
    result.should include %(time="#{formatted_time}")
  end

  it 'has the correct alias' do
    sender_alias = 'jane_alias'
    result = create_status_message(sender_alias: sender_alias).to_s
    result.should include %(alias="#{sender_alias}")
  end

  it 'has the correct status' do
    status = 'status'
    result = create_status_message(status: status).to_s
    result.should include %(type="#{status}")
  end

  it 'is a status tag' do
    create_status_message.to_s.should =~ /^<status/
  end

  it 'ends in a newline' do
    create_status_message.to_s.should =~ /\n$/
  end

  def create_status_message(opts = {})
    opts[:sender_screen_name] ||= 'jim_sender'
    opts[:time] ||= Time.now
    opts[:sender_alias] ||= 'jane_alias'
    opts[:status] ||= 'status'

    Pidgin2Adium::StatusMessage.new(opts[:sender_screen_name], opts[:time], opts[:sender_alias], opts[:status])
  end
end
