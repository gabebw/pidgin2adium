describe Pidgin2Adium::Message do
  context '#time' do
    it 'returns the parsed time' do
      time = Time.now

      message = Pidgin2Adium::Message.new(time: time)

      expect(message.time).to eq time
    end
  end

  context '#sender_alias' do
    it 'returns the alias of the sender' do
      message = Pidgin2Adium::Message.new(sender_alias: 'Gabe')

      expect(message.sender_alias).to eq 'Gabe'
    end
  end

  context '#sender_screen_name' do
    it 'returns the screen name of the sender' do
      message = Pidgin2Adium::Message.new(sender_screen_name: 'mySN')

      expect(message.sender_screen_name).to eq 'mySN'
    end
  end

  context '#body' do
    it 'returns the message body' do
      message = Pidgin2Adium::Message.new(body: 'Hello')

      expect(message.body).to eq 'Hello'
    end
  end
end
