require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Pidgin2Adium, "#parse" do
  let(:aliases) { '' }

  context "on failure" do
    before do
      @weird_logfile_path = File.join(@spec_directory, 'logfile.foobar')
    end

    it "returns falsy when file is not text or html" do
      Pidgin2Adium.parse(@weird_logfile_path, aliases).should be_false
    end

    it "logs an error" do
      Pidgin2Adium.parse(@weird_logfile_path, aliases).should be_false
    end

    it "gracefully handles nonexistent files" do
      Pidgin2Adium.parse("i_do_not_exist.html", aliases).should be_false
      Pidgin2Adium.parse("i_do_not_exist.txt", aliases).should be_false
    end
  end

  context "on success" do
    context "for a text file" do
      it "returns a Chat instance" do
        result = Pidgin2Adium.parse(@text_logfile_path, aliases)
        result.should be_instance_of(Pidgin2Adium::Chat)
      end
    end

    context "for an htm file" do
      it "returns a Chat instance" do
        result = Pidgin2Adium.parse(@htm_logfile_path, aliases)
        result.should be_instance_of(Pidgin2Adium::Chat)
      end
    end

    context "for an html file" do
      it "returns a Chat instance" do
        result = Pidgin2Adium.parse(@html_logfile_path, aliases)
        result.should be_instance_of(Pidgin2Adium::Chat)
      end
    end
  end
end
