require 'spec_helper'
require 'pidgin2adium/log_converter'
require 'fileutils'

describe "LogConverter" do
  before(:each) do
    @converter = Pidgin2Adium::LogConverter.new(@logfile_path,
                                                @aliases,
                                                { :output_dir => @output_dir })
    Pidgin2Adium::LogConverter.stub!(:puts).and_return(nil)
    Pidgin2Adium::LogConverter.stub!(:log_msg)
  end

  describe "with non-existent input dir" do
    it "should raise ENOENT with correct error message" do
      lambda do
        converter = Pidgin2Adium::LogConverter.new("nonexistent-dir",
                                                   @aliases)
      end.should raise_error(Errno::ENOENT)
    end
  end

  # it "should have correct output when files don't exist" do
  #   FileUtils.rm_f(File.join(@output_dir, '*'))
  #   # Will only convert 2 files because the .htm file == the .html file
  #   Pidgin2Adium.should_receive(:log_msg).with(/Converted 2 files of 3 total/)
  #   @converter.start()
  # end

  # it "should have correct output when files do exist" do
  #   @converter.start() # create files
  #   Pidgin2Adium.should_receive(:log_msg).with(/Converted 0 files of 3 total/)
  #   @converter.start()
  # end

  describe "#get_all_chat_files" do
    it "should return correct listings" do
      files = @converter.get_all_chat_files
      dir = File.join(File.dirname(File.expand_path(__FILE__)),
                      'logfiles')

      expected_files = %w{2006-12-21.223606.txt
        2008-01-15.071445-0500PST.htm
        2008-01-15.071445-0500PST.html}.map!{|f| File.join(dir, f) }

      files.sort.should == expected_files.sort
    end
  end
end
