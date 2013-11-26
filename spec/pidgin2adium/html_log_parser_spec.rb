describe Pidgin2Adium::HtmlLogParser do
  [nil,
   :span_tag_instead_of_font_tag,
   :no_tag_around_body
  ].each do |format|
    context "with format #{format.inspect}" do
      it 'can parse out timestamps' do
        messages = result_of_parsing do |b|
          b.message 'hi', time: '2007-01-17 18:59:42', format: format
        end

        expect(messages.first.time).to eq Time.parse('2007-01-17 18:59:42')
      end

      it 'can parse out the alias of the sender' do
        messages = result_of_parsing do |b|
          b.message 'hi', sender_alias: 'Gabe B-W', format: format
        end

        expect(messages.first.sender_alias).to eq 'Gabe B-W'
      end

      # no_tag_around_body breaks
      it 'can parse out the message body' do
        messages = result_of_parsing do |b|
          b.message 'yo', format: format
        end

        expect(messages.first.body).to eq 'yo'
      end

      # all of 'em break
      it 'can parse out the message body when it contains HTML' do
        html = '<a HREF="http://software.johnroark.net/">http://software.johnroark.net/</a>'
        body = "check it: #{html} haha"

        messages = result_of_parsing do |b|
          b.message body, format: format
        end

        expect(messages.first.body).to eq body.downcase
      end

      it 'can parse out the sender screen name' do
        messages = result_of_parsing do |b|
          b.first_line my_screen_name: 'dragon screenname', their_screen_name: 'OtherPersonScreenName'
          b.message 'hi', sender_screen_name: 'dragon screenname', format: format
          b.message 'hello', sender_screen_name: 'OtherPersonScreenName', format: format
        end

        expect(messages[0].sender_screen_name).to eq 'dragon screenname'
        expect(messages[1].sender_screen_name).to eq 'OtherPersonScreenName'
      end
    end
  end

  def result_of_parsing(&block)
    file = create_chat_file('file.html', &block)
    parser = Pidgin2Adium::HtmlLogParser.new(file.path)
    parser.parse
  end
end
