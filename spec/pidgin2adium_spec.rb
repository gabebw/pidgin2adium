describe Pidgin2Adium, ".parse" do
  context "with bad input" do
    it "returns false when file is not text or html" do
      Pidgin2Adium.parse(non_html_or_txt_path).should be_false
    end

    it "returns false for nonexistent files" do
      Pidgin2Adium.parse('i_do_not_exist.html').should be_false
      Pidgin2Adium.parse('i_do_not_exist.txt').should be_false
    end

    def non_html_or_txt_path
      'logfile.foobar'
    end
  end

  context "with good input" do
    context "for a text file" do
      it "returns an object that knows all lines"
    end

    context "for an html file" do
      it "returns data about every line" do
        messages = result_of_parsing do |b|
          b.message 'yo'
          b.message 'hello'
        end

        expect(messages.map(&:body)).to eq %w(yo hello)
      end

      def result_of_parsing(&block)
        file = create_chat_file('file.html', &block)
        Pidgin2Adium.parse(file.path)
      end
    end
  end
end
