# Tests for bin/pidgin2adium

require 'spec_helper'

describe "Pidgin2Adium_bin" do
  before(:each) do
    @nonexistent_logfile_path = "./nonexistent_logfile_path/"
    @script = File.join(@current_dir, '..', 'bin', 'pidgin2adium')
  end

  describe "normal operation" do
    before(:each) do
      FileUtils.rm_r(@output_dir, :force => true)
      system("#{@script} -i #{@logfile_path} -o #{@output_dir} -a #{@aliases} 2>&1 > /dev/null")
    end
    # Note: spec_helper.rb removes @output_dir in an after(:all) hook

    it "should create the top-level output_dir" do
      File.directory?(@output_dir).should be_true
    end

    describe "for screenname 'othersn' (from HTML log)" do
      before(:each) do
        @xml_file = File.join(@output_dir,
                              'AIM.othersn',
                              'aolsystemmsg',
                              'aolsystemmsg (2008-01-15T07.14.45-0500).chatlog',
                              'aolsystemmsg (2008-01-15T07.14.45-0500).xml')
        @test_output_file = File.join(@current_dir, 'test-output', 'html_log_output.xml')
      end
      it "should create the correct directory for the screenname" do
        sn_dir = File.join(@output_dir, 'AIM.othersn')
        File.directory?(sn_dir).should be_true
      end

      it "should create the directory for the partner's SN" do
        partner_sn_dir = File.join(@output_dir, 'AIM.othersn', 'aolsystemmsg')
        File.directory?(partner_sn_dir).should be_true
      end
      it "should create a .chatlog directory for the specific chat" do
        chatlog_dir = File.join(@output_dir,
                                'AIM.othersn',
                                'aolsystemmsg',
                                'aolsystemmsg (2008-01-15T07.14.45-0500).chatlog')
        File.directory?(chatlog_dir).should be_true
      end

      it "should create the XML file for the chat" do
        File.file?(@xml_file).should be_true
      end

      it "should have a non-empty XML file" do
        File.size?(@xml_file).should_not be_nil
      end

      it "should have an XML file identical to the test output" do
        File.identical?(@xml_file, @test_output_file).should_not be_nil
      end
    end
  end
end
