require 'spec_helper'

describe Pidgin2Adium::ParserFactory do
  let(:aliases) { '' }
  let(:force_conversion) { false }

  %w(html htm HTML).each do |html_extension|
    context "when passed a .#{html_extension} file" do
      let(:logfile_path) {  }
      it 'returns an HtmlLogParser' do
        logfile_path = "whatever.#{html_extension}"
        factory = Pidgin2Adium::ParserFactory.new(aliases, force_conversion)
        factory.parser_for(logfile_path).should be_a Pidgin2Adium::HtmlLogParser
      end
    end
  end

  %w(txt TXT).each do |text_extension|
    context "when passed a .#{text_extension} file" do
      let(:logfile_path) {  }
      it 'returns an TextLogParser' do
        logfile_path = "whatever.#{text_extension}"
        factory = Pidgin2Adium::ParserFactory.new(aliases, force_conversion)
        factory.parser_for(logfile_path).should be_a Pidgin2Adium::TextLogParser
      end
    end
  end

  context 'when passed a non-HTML, non-text file' do
    it "returns falsy" do
      Pidgin2Adium.logger.stubs(:error)
      factory = Pidgin2Adium::ParserFactory.new(aliases, force_conversion)
      factory.parser_for('foo.bar').should be_false
    end
  end
end
