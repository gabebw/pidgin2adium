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
        @sn_dir = File.join(@output_dir, 'AIM.othersn')
        @partner_sn_dir = File.join(@sn_dir, 'aolsystemmsg')
        @chatlog_dir = File.join(@partner_sn_dir, 'aolsystemmsg (2008-01-15T07.14.45-0500).chatlog')
        @chatlog_dir = File.join(@partner_sn_dir, 'aolsystemmsg (2008-01-15T07.14.45-0500).chatlog')
        @xml_file = File.join(@chatlog_dir, 'aolsystemmsg (2008-01-15T07.14.45-0500).xml')
        @test_output_file = File.join(@current_dir, 'test-output', 'html_log_output.xml')
      end
      it "should create the correct directory for the screenname" do
        File.directory?(@sn_dir).should be_true
      end

      it "should create the directory for the partner's SN" do
        File.directory?(@partner_sn_dir).should be_true
      end
      it "should create a .chatlog directory for the specific chat" do
        File.directory?(@chatlog_dir).should be_true
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

  describe "for screenname 'awesomesn' (from text log)" do
    before(:each) do
      @sn_dir = File.join(@output_dir, 'AIM.awesomesn')
      @partner_sn_dir = File.join(@sn_dir, 'BUDDY_PERSON')
      @chatlog_dir = File.join(@partner_sn_dir, "BUDDY_PERSON (2006-12-21T22.36.06#{@current_tz_offset}).chatlog")
      @xml_file = File.join(@chatlog_dir, "BUDDY_PERSON (2006-12-21T22.36.06#{@current_tz_offset}).xml")
      @test_output_file = File.join(@current_dir, 'test-output', 'text_log_output.xml')
    end

    it "should create the correct directory for the screenname" do
      File.directory?(@sn_dir).should be_true
    end

    it "should create the directory for the partner's SN" do
      File.directory?(@partner_sn_dir).should be_true
    end
    it "should create a .chatlog directory for the specific chat" do
      File.directory?(@chatlog_dir).should be_true
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
