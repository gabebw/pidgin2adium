require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Pidgin2Adium" do
  before(:each) do
    @current_dir = File.dirname(__FILE__)

    @aliases = %w{gabebw gabeb-w gbw me}.join(',')

    @nonexistent_logfile_path = "./nonexistent_logfile_path/"
    @logfile_path = File.join(@current_dir, "logfiles/") + '/'

    @text_logfile_path = "#{@logfile_path}2006-12-21.223606.txt"
    @htm_logfile_path = "#{@logfile_path}2008-01-15.071445-0500PST.htm"
    @html_logfile_path = "#{@logfile_path}2008-01-15.071445-0500PST.html"

    # "Kernel gets mixed in to an object, so you need to stub [its methods] on the object
    # itself." - http://www.ruby-forum.com/topic/128619
    Pidgin2Adium.stub!(:puts).and_return(nil)
  end
  describe "constants" do
    it "should set ADIUM_LOG_DIR correctly" do
      Pidgin2Adium::ADIUM_LOG_DIR.should == File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') + '/'
    end

    it "should set BAD_DIRS correctly" do
      Pidgin2Adium::BAD_DIRS.should == %w{. .. .DS_Store Thumbs.db .system}
    end
  end # constants

  describe "utility methods" do
    before(:each) do
      Pidgin2Adium.stub!(:log_msg).and_return(nil)
    end

    describe "oops" do
      it "should add a message to @@oops_messages" do
        message = "Oops! I messed up!"
        Pidgin2Adium.oops(message)
        Pidgin2Adium.send(:class_variable_get, :@@oops_messages).should == [message]
      end
    end

    describe "error" do
      it "should add a message to @@error_messages" do
        err_message = "Error! I *really* messed up!"
        Pidgin2Adium.error(err_message)
        Pidgin2Adium.send(:class_variable_get, :@@error_messages).should == [err_message]
      end
    end

    describe "delete_search_indexes" do
      before(:each) do
        @dirty_file = File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
        @log_index_file = File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
      end

      describe "when search indices exist" do
        before(:each) do
          `touch #{@dirty_file}`
          `touch #{@log_index_file}`
        end
        it "should delete the search indices when they are writeable" do
          [@dirty_file, @log_index_file].each do |f|
            `chmod +w #{f}` # make writeable
          end
          Pidgin2Adium.delete_search_indexes()
          File.exist?(@dirty_file).should be_false
          File.exist?(@log_index_file).should be_false
        end

        it "should give an error message when they are not writable" do
          [@dirty_file, @log_index_file].each do |f|
            `chmod -w #{f}` # make unwriteable
          end
          Pidgin2Adium.should_receive(:error).with("File exists but is not writable. Please delete it yourself: #{@dirty_file}")
          Pidgin2Adium.should_receive(:error).with("File exists but is not writable. Please delete it yourself: #{@log_index_file}")
          Pidgin2Adium.should_receive(:log_msg).with("...done.")
          Pidgin2Adium.should_receive(:log_msg).with("When you next start the Adium Chat Transcript Viewer, " +
                                                     "it will re-index the logs, which may take a while.")
          Pidgin2Adium.delete_search_indexes()
          File.exist?(@dirty_file).should be_true
          File.exist?(@log_index_file).should be_true
        end
      end # when search indices exist
    end # delete_search_indexes
  end # utility methods

  describe "parse" do
    describe "failure" do
      before(:each) do
        @weird_logfile_path = File.join(@current_dir, 'logfile.foobar')
      end
      it "should give an error when file is not text or html" do
        Pidgin2Adium.should_receive(:error).with(/Doing nothing, logfile is not a text or html file/)
        Pidgin2Adium.parse(@weird_logfile_path, @aliases).should be_false
      end

      it "should gracefully handle nonexistent files" do
        Pidgin2Adium.parse("i_do_not_exist.html", @aliases).should be_false
        Pidgin2Adium.parse("i_do_not_exist.txt", @aliases).should be_false
      end
    end # failure

    describe "success" do
      context "for a text file" do
        specify { Pidgin2Adium.parse(@text_logfile_path, @aliases).should be_instance_of(Pidgin2Adium::LogFile) }
      end
      context "for an htm file" do
        specify { Pidgin2Adium.parse(@htm_logfile_path, @aliases).should be_instance_of(Pidgin2Adium::LogFile) }
      end
      context "for an html file" do
        specify { Pidgin2Adium.parse(@html_logfile_path, @aliases).should be_instance_of(Pidgin2Adium::LogFile) }
      end
    end # success
  end # parse

  describe "parse_and_generate" do
    before(:each) do
      @nonexistent_output_dir = File.join(@current_dir, "nonexistent_output_dir/")
      @output_dir = File.join(@current_dir, "output-dir/")
    end
    after(:each) do
      FileUtils.rm_r(@nonexistent_output_dir, :force => true)
    end
    describe "failure" do
      describe "when output dir does not exist" do
        before(:each) do
          @opts = { :output_dir => @nonexistent_output_dir }
        end

        it "should return false when it can't create the output dir" do
          `chmod -w .`
          Pidgin2Adium.parse_and_generate(@logfile_path,
                                          @aliases,
                                          @opts).should be_false
          `chmod +w .`
        end
      end

      describe "when output dir does exist" do
        before(:each) do
          @opts = { :output_dir => @output_dir }
        end

        describe "when :force is not set" do
          it "should return FILE_EXISTS if file already exists" do
            File.new(File.join(@logfile_path, "blah.txt"), 'w').close # create file
            Pidgin2Adium.parse_and_generate(@logfile_path,
                                            @aliases,
                                            @opts).should be_false
            Pidgin2Adium.parse_and_generate(@logfile_path,
                                            @output_dir,
                                            @opts).should be_false
          end
        end # :force is not set
      end # output dir does exist
    end # failure
  end # parse_and_generate
end
