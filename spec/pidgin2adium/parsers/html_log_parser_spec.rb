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

    {
      'Gabe B-W logged in.' => 'online',
      'Gabe B-W logged out.' => 'offline',
      'Gabe B-W has signed on.' => 'online',
      'Gabe B-W has signed off.' => 'offline',
      'Gabe B-W has gone away.' => 'away',
      'Gabe B-W is no longer away.' => 'available',
      'Gabe B-W has become idle.' => 'idle',
      'Gabe B-W is no longer idle.' => 'available'
    }.each do |line, status|
      it 'correctly detects status messages of format #{line}' do
        message = first_line_of_chat do |b|
          b.first_line
          b.status line
        end

        message.status.should == status
      end
    end

    it 'correctly detects libpurple events' do
      message = first_line_of_chat do |b|
        b.first_line
        b.status 'Starting transfer of kitten.jpg from Gabe B-W'
      end

      message.event_type.should == 'libpurpleEvent'
    end

    it 'correctly detects non-libpurple events' do
      message = first_line_of_chat do |b|
        b.first_line
        b.status 'You missed 8 messages from Gabe B-W because they were too large'
      end

      message.event_type.should == 'chat-error'
    end

    it 'does not build Messages for ignored events' do
      chat = build_chat do |b|
        b.first_line
        b.status 'Gabe B-W is now known as gbw.'
      end

      chat.lines.should == [nil]
    end

    it 'correctly detects auto-reply messages' do
      message = first_line_of_chat do |b|
        b.first_line
        b.auto_reply 'I ran out for a bit'
      end

      message.should be_instance_of(Pidgin2Adium::AutoReplyMessage)
      message.body.should == 'I ran out for a bit'
    end

    it 'parses out the screen name for the user who is doing the logging' do
      message = first_line_of_chat('Gabe B-W') do |b|
        b.first_line from: 'from', to: 'to'
        b.message 'whatever', from: 'from', from_alias: 'Gabe B-W'
      end

      message.sender_screen_name.should == 'from'
    end

    it 'parses out the alias for the user who is doing the logging' do
      message = first_line_of_chat do |b|
        b.first_line from: 'from', to: 'to'
        b.message 'whatever', from_alias: 'Jack Alias'
      end

      message.sender_alias.should == 'Jack Alias'
    end

    it 'parses out the screen name for the user on the other end' do
      message = first_line_of_chat('my-alias') do |b|
        b.first_line from: 'from'
        b.message 'whatever', from: 'from', from_alias: 'my-alias'
      end

      message.sender_screen_name.should == 'from'
    end

    it 'parses out the alias for the user on the other end' do
      message = first_line_of_chat('my-alias') do |b|
        b.first_line from: 'from'
        b.message 'whatever', from: 'from', from_alias: 'my-alias'
      end

      message.sender_alias.should == 'my-alias'
    end

    it 'parses out the time' do
      message = first_line_of_chat do |b|
        b.first_line
        b.message 'whatever', time: '2008-01-15 07:14:45'
      end

      message.time.should == DateTime.parse('2008-01-15 07:14:45')
    end

    it 'parses out the body' do
      message = first_line_of_chat do |b|
        b.first_line
        b.message 'body'
      end

      message.body.should == 'body'
    end

    it 'double quotes hrefs in the body' do
      body_with_link = %q(<a href='http://google.com'>first</a>)
      message = first_line_of_chat do |b|
        b.first_line
        b.message body_with_link
      end

      message.body.should == body_with_link.gsub("'", '"')
    end
  end

  def build_chat(aliases = 'Gabe B-W', &block)
    file = create_chat_file('file.html', &block)
    Pidgin2Adium::HtmlLogParser.new(file.path, aliases).parse
  end

  def first_line_of_chat(aliases = 'Gabe B-W', &block)
    build_chat(aliases, &block).lines.first
  end
end
