describe Pidgin2Adium, ".parse" do
  context "with bad input" do
    it "returns false when file is not text or html" do
      expect(Pidgin2Adium.parse(non_html_or_txt_path, aliases)).to be_falsey
    end

    it "returns false for nonexistent files" do
      expect(Pidgin2Adium.parse('i_do_not_exist.html', aliases)).to be_falsey
      expect(Pidgin2Adium.parse('i_do_not_exist.txt', aliases)).to be_falsey
    end

    def non_html_or_txt_path
      'logfile.foobar'
    end
  end

  context "with good input" do
    context "for a text file" do
      it "returns a Chat instance" do
        result = Pidgin2Adium.parse(text_logfile_path, aliases)
        expect(result).to be_instance_of(Pidgin2Adium::Chat)
      end
    end

    context "for an htm file" do
      it "returns a Chat instance" do
        result = Pidgin2Adium.parse(htm_logfile_path, aliases)
        expect(result).to be_instance_of(Pidgin2Adium::Chat)
      end
    end

    context "for an html file" do
      it "returns a Chat instance" do
        result = Pidgin2Adium.parse(html_logfile_path, aliases)
        expect(result).to be_instance_of(Pidgin2Adium::Chat)
      end
    end
  end

  def spec_directory
    File.dirname(__FILE__)
  end

  def logfile_path
    Pathname.new(File.join(spec_directory, "support", "logfiles"))
  end

  def text_logfile_path
    logfile_path.join("2006-12-21.223606.txt")
  end

  def htm_logfile_path
    logfile_path.join("2008-01-15.071445-0500PST.htm")
  end

  def html_logfile_path
    logfile_path.join("2008-01-15.071445-0500PST.html")
  end

  def aliases
    ''
  end
end
