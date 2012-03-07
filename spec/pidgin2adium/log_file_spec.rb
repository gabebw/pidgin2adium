require 'spec_helper'

describe "LogFile" do
  before do
    @user_SN = "gabebw"
    @user_alias = "Gabe B-W"

    @partner_SN = "matz"
    @partner_alias = "Yukihiro Matsumoto"

    @start_time = "2010-08-10T22:55:07-0500"
    times = [@start_time,
             "2010-08-10T22:55:12-0500",
             "2010-08-10T22:55:17-0500",
             "2010-08-10T22:55:22-0500"]

    message_1 = Pidgin2Adium::XMLMessage.new(@user_SN, @start_time,
                                             @user_alias, "Hello!")
    message_2 = Pidgin2Adium::StatusMessage.new(@partner_SN, times[1],
                                                @partner_alias, "Matz has gone away")

    message_3 = Pidgin2Adium::Event.new(@user_SN, times[2], @user_alias,
                                        "gabebw logged in.", 'online')

    message_4 = Pidgin2Adium::AutoReplyMessage.new(@partner_SN, times[3],
                                                   @partner_alias,
                                                   "This is an away message")

    @messages = [message_1, message_2, message_3, message_4]
    @logfile = Pidgin2Adium::LogFile.new(@messages, 'aim', @user_SN,
                                         @partner_SN, @start_time)
  end

  describe "attributes" do
    [:chat_lines, :service, :user_SN, :partner_SN, :adium_chat_time_start].each do |attribute|
      it "has a reader for #{attribute}" do
        @logfile.should respond_to(attribute)
      end
    end
  end

  describe "#to_s" do
    it "should return the correct string" do
      output = @logfile.to_s
      output.should == @messages.map{|m| m.to_s}.join
    end
  end


  describe "enumerable methods" do
    it "should include Enumerable" do
      Pidgin2Adium::LogFile.included_modules.include?(Enumerable).should be_true
    end

    describe "#each_with_index" do
      it "yields the correct messages, in order" do
        @logfile.each_with_index do |msg, n|
          msg.should == @messages[n]
        end
      end
    end

    describe "#max" do
      it "returns the most recent message" do
        @logfile.max.should == @messages.last
      end
    end

    describe "#min" do
      it "returns the oldest message" do
        @logfile.min.should == @messages.first
      end
    end
  end

  describe "#write_out" do
    before do
      @output_file_path = File.join(@output_dir,
                            'AIM.gabebw',
                            'matz',
                            "matz (#{@start_time}).chatlog",
                            "matz (#{@start_time}).xml")
    end

    describe "when file does not exist" do
      before do
        FileUtils.rm_rf(File.join(@output_dir, 'AIM.gabebw'))
        @output_file = @logfile.write_out(false, @output_dir)
      end

      it "writes out the correct content" do
        IO.read(@output_file).should include(@logfile.to_s)
      end

      it "writes out the correct header" do
        header = %(<?xml version="1.0" encoding="UTF-8" ?>\n) +
                  %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="gabebw" service="AIM">\n)
        IO.read(@output_file).should =~ /^#{Regexp.escape(header)}/
      end

      it "writes out the closing </chat> tag" do
        IO.read(@output_file).should =~ %r{</chat>$}
      end

      it "writes to the correct path" do
        @output_file.should == @output_file_path
      end
    end

    describe "when file exists" do
      before do
        FileUtils.mkdir_p(File.dirname(@output_file_path))
        File.new(@output_file_path, 'w').close
      end

      it "returns FILE_EXISTS" do
        output_file = @logfile.write_out(false, @output_dir)
        output_file.should == Pidgin2Adium::FILE_EXISTS
      end

      it "returns output file path if overwrite is true" do
        output_file = @logfile.write_out(true, @output_dir)
        output_file.should == @output_file_path
      end
    end

    describe "permissions problems" do
      describe "with output dir" do
        before do
          FileUtils.rm_rf(@output_dir)
          `chmod -w #{File.dirname(@output_dir)}`
        end

        after do
          `chmod +w #{File.dirname(@output_dir)}`
        end

        it "returns false if it can't create the output dir" do
          @logfile.write_out(false, @output_dir).should be_false
        end
      end

      describe "with output file" do
        before do
          # Make parent dir unwriteable because creating the
          # file itself and making it unwriteable returns
          # FILE_EXISTS
          @output_file_parent_dir = File.dirname(@output_file_path)
          FileUtils.mkdir_p(@output_file_parent_dir)
          `chmod -w '#{@output_file_parent_dir}'`
        end

        after do
          `chmod +w '#{@output_file_parent_dir}'`
        end

        it "returns false if it can't open the output file for writing" do
          @logfile.write_out(false, @output_dir).should be_false
        end
      end
    end
  end
end
