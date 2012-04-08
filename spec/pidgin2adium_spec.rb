require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Pidgin2Adium, "utility methods" do
  include_context "fake logger"

  context '.logger getters and setters' do
    it 'gets/sets the logger' do
      Pidgin2Adium.logger = 'hi'
      Pidgin2Adium.logger.should == 'hi'
    end
  end

  it { should delegate(:error).to(:logger).with_arguments('hi') }
  it { should delegate(:warn).to(:logger).with_arguments('hi') }
  it { should delegate(:log).to(:logger).with_arguments('hi') }
end

describe Pidgin2Adium, "#parse" do
  include_context "fake logger"
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
      it "returns a LogFile instance" do
        result = Pidgin2Adium.parse(@text_logfile_path, aliases)
        result.should be_instance_of(Pidgin2Adium::LogFile)
      end
    end

    context "for an htm file" do
      it "returns a LogFile instance" do
        result = Pidgin2Adium.parse(@htm_logfile_path, aliases)
        result.should be_instance_of(Pidgin2Adium::LogFile)
      end
    end

    context "for an html file" do
      it "returns a LogFile instance" do
        result = Pidgin2Adium.parse(@html_logfile_path, aliases)
        result.should be_instance_of(Pidgin2Adium::LogFile)
      end
    end
  end
end
