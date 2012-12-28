describe Pidgin2Adium::HtmlLogParser do
  context '#parse' do
    it 'returns a Chat with the correct number of lines' do
      chat = build_chat do |b|
        b.first_line
        3.times { b.message }
      end

      chat.lines.size.should == 3
    end

    it 'returns a Chat with the correct message type' do
      chat = build_chat do |b|
        b.first_line
        b.message 'first'
        b.message 'second'
      end

      chat.lines.map(&:class).should == [Pidgin2Adium::XMLMessage] * 2
    end

    it 'parses out the screen name for the user who is doing the logging' do
      message = build_chat('Gabe B-W') do |b|
        b.first_line from: 'from', to: 'to'
        b.message 'whatever', from: 'from', from_alias: 'Gabe B-W'
      end.lines.first

      message.sender_screen_name.should == 'from'
    end

    it 'parses out the alias for the user who is doing the logging' do
      message = build_chat do |b|
        b.first_line from: 'from', to: 'to'
        b.message 'whatever', from_alias: 'Jack Alias'
      end.lines.first

      message.sender_alias.should == 'Jack Alias'
    end

    it 'parses out the screen name for the user on the other end' do
      message = build_chat('my-alias') do |b|
        b.first_line from: 'from'
        b.message 'whatever', from: 'from', from_alias: 'my-alias'
      end.lines.first

      message.sender_screen_name.should == 'from'
    end

    it 'parses out the alias for the user on the other end' do
      message = build_chat('my-alias') do |b|
        b.first_line from: 'from'
        b.message 'whatever', from: 'from', from_alias: 'my-alias'
      end.lines.first

      message.sender_alias.should == 'my-alias'
    end

    it 'parses out the time' do
      message = build_chat do |b|
        b.first_line
        b.message 'whatever', time: '2008-01-15 07:14:45'
      end.lines.first

      message.time.should == DateTime.parse('2008-01-15 07:14:45')
    end

    it 'parses out the body' do
      message = build_chat do |b|
        b.first_line
        b.message 'body'
      end.lines.first

      message.body.should == 'body'
    end

    it 'double quotes hrefs in the body' do
      body_with_link = %q(<a href='http://google.com'>first</a>)
      message = build_chat do |b|
        b.first_line
        b.message body_with_link
      end.lines.first

      message.body.should == body_with_link.gsub("'", '"')
    end
  end

  def build_chat(aliases = 'Gabe B-W', &block)
    path = create_chat_file('file.html', &block)
    Pidgin2Adium::HtmlLogParser.new(path, aliases).parse
  end
end
