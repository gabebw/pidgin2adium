require 'spec_helper'
require 'pidgin2adium/log_converter'
require 'fileutils'

describe Pidgin2Adium::LogConverter do
  include_context "fake logger"

  before do
    @converter = Pidgin2Adium::LogConverter.new(@logfile_path, '',
                                                { :output_dir => @output_dir })
  end

  describe "with non-existent input dir" do
    it "should raise ENOENT with correct error message" do
      lambda do
        converter = Pidgin2Adium::LogConverter.new("nonexistent-dir", '')
      end.should raise_error(Errno::ENOENT)
    end
  end

  it "should have correct output when files don't exist" do
    FileUtils.rm_f(File.join(@output_dir, '*'))
    # Will only convert 2 files because the .htm file == the .html file
    @converter.start
    Pidgin2Adium.logger.should have_received(:log).with(regexp_matches(/Converted 2 files of 3 total/))
  end

  it "should have correct output when files do exist" do
    2.times { @converter.start }
    Pidgin2Adium.logger.should have_received(:log).with(regexp_matches(/Converted 0 files of 3 total/)).at_least_once
  end

  describe "#get_all_chat_files" do
    it "should return correct listings" do
      files = @converter.get_all_chat_files

      expected_files = %w(2006-12-21.223606.txt
        2008-01-15.071445-0500PST.htm
        2008-01-15.071445-0500PST.html).map{|f| File.join(@logfile_path, f) }

      files.sort.should == expected_files.sort
    end
  end
end
