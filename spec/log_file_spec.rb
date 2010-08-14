require 'spec_helper'

describe "LogFile" do
  before(:each) do
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
    it "should have chat_lines readable" do
      @logfile.should respond_to(:chat_lines)
    end

    it "should have service readable" do
      @logfile.should respond_to(:service)
    end

    it "should have user_SN readable" do
      @logfile.should respond_to(:user_SN)
    end

    it "should have partner_SN readable" do
      @logfile.should respond_to(:partner_SN)
    end

    it "should have adium_chat_time_start readable" do
      @logfile.should respond_to(:adium_chat_time_start)
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
      it "should yield the correct messages" do
        @logfile.each_with_index do |msg, n|
          msg.should == @messages[n]
        end
      end
    end
  end

  describe "#write_out" do
    before(:each) do
      @output_file_path = File.join(@output_dir,
                            'AIM.gabebw',
                            'matz',
                            "matz (#{@start_time}).chatlog",
                            "matz (#{@start_time}).xml")
    end

    describe "when file does not exist" do
      before(:each) do
        FileUtils.rm_r(File.join(@output_dir, 'AIM.gabebw'),
                       :force => true)
        @output_file = @logfile.write_out(false, @output_dir)
      end

      it "should write out the correct content" do
        IO.read(@output_file).include?(@logfile.to_s).should be_true
      end

      it "should write out the correct header" do
        header = sprintf('<?xml version="1.0" encoding="UTF-8" ?>'+"\n"+
                         '<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="gabebw" service="AIM">'+"\n")
        IO.read(@output_file).should =~ /^#{Regexp.escape(header)}/
      end

      it "should write out the closing </chat> tag" do
        IO.read(@output_file).should =~ %r{</chat>$}
      end

      it "should write to the correct path" do
        @output_file.should == @output_file_path
      end
    end

    describe "when file exists" do
      before(:each) do
        FileUtils.mkdir_p(File.dirname(@output_file_path))
        File.new(@output_file_path, 'w').close
      end
      it "should return FILE_EXISTS" do
        output_file = @logfile.write_out(false, @output_dir)
        output_file.should == Pidgin2Adium::FILE_EXISTS
      end
      it "should return output file path if overwrite is true" do
        output_file = @logfile.write_out(true, @output_dir)
        output_file.should == @output_file_path
      end
    end

    describe "permissions problems" do
      describe "with output dir" do
        before(:each) do
          FileUtils.rm_r(@output_dir, :force => true)
          `chmod -w #{File.dirname(@output_dir)}`
        end

        after(:each) do
          `chmod +w #{File.dirname(@output_dir)}`
        end

        it "should return false if it can't create the output dir" do
          @logfile.write_out(false, @output_dir).should be_false
        end
      end

      describe "with output file" do
        before(:each) do
          # Make parent dir unwriteable because creating the
          # file itself and making it unwriteable returns
          # FILE_EXISTS
          @output_file_parent_dir = File.dirname(@output_file_path)
          FileUtils.mkdir_p(@output_file_parent_dir)
          `chmod -w '#{@output_file_parent_dir}'`
        end

        after(:each) do
          `chmod +w '#{@output_file_parent_dir}'`
        end

        it "should return false if it can't open the output file for writing" do
          @logfile.write_out(false, @output_dir).should be_false
        end
      end
    end
  end
end
