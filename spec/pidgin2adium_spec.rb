require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Pidgin2Adium, "constants" do
  it "should set ADIUM_LOG_DIR correctly" do
    Pidgin2Adium::ADIUM_LOG_DIR.should == File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') + '/'
  end

  it "should set BAD_DIRS correctly" do
    Pidgin2Adium::BAD_DIRS.should == %w{. .. .DS_Store Thumbs.db .system}
  end
end

describe Pidgin2Adium, "utility methods" do
  include_context "fake logger"

  before(:all) do
    @nonexistent_logfile_path = "./nonexistent_logfile_path/"
  end

  before do
    # "Kernel gets mixed in to an object, so you need to stub [its methods] on the object
    # itself." - http://www.ruby-forum.com/topic/128619
    Pidgin2Adium.stubs(:puts => nil) # Doesn't work in the before(:all) block
  end

  context '.logger=' do
    it 'sets the logger' do
      Pidgin2Adium.logger=('hi')
      Pidgin2Adium.logger.should == 'hi'
    end
  end

  context '.logger' do
    it 'gets the logger' do
      Pidgin2Adium.logger=('hi')
      Pidgin2Adium.logger.should == 'hi'
    end
  end

  describe ".oops" do
    it "delegates to the logger" do
      Pidgin2Adium.oops('hi')
      stubbed_logger.should have_received(:oops).with('hi')
    end
  end

  describe ".error" do
    it "delegates to the logger" do
      error = 'hi'
      Pidgin2Adium.error('hi')
      stubbed_logger.should have_received(:error).with('hi')
    end
  end

  describe ".log" do
    it "delegates to the logger" do
      log = 'hi'
      Pidgin2Adium.log('hi')
      stubbed_logger.should have_received(:log).with('hi')
    end
  end

  describe "#delete_search_indexes" do
    before do
      @dirty_file = File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
      @log_index_file = File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
    end

    describe "when search indices exist" do
      before do
        `touch #{@dirty_file}`
        `touch #{@log_index_file}`
      end

      after do
        # Recreate search indices
        `touch #{@dirty_file}`
        `touch #{@log_index_file}`
        [@dirty_file, @log_index_file].each do |f|
          `chmod +w #{f}` # make writeable
        end
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
        Pidgin2Adium.stubs(:error => nil, :log => nil)
        Pidgin2Adium.delete_search_indexes()
        Pidgin2Adium.should have_received(:error).with("File exists but is not writable. Please delete it yourself: #{@dirty_file}")
        Pidgin2Adium.should have_received(:error).with("File exists but is not writable. Please delete it yourself: #{@log_index_file}")
        Pidgin2Adium.should have_received(:log).with("...done.")
        Pidgin2Adium.should have_received(:log).with("When you next start the Adium Chat Transcript Viewer, " +
                                                    "it will re-index the logs, which may take a while.")
        File.exist?(@dirty_file).should be_true
        File.exist?(@log_index_file).should be_true
      end
    end # when search indices exist
  end # delete_search_indexes
end

describe Pidgin2Adium, "#parse" do
  include_context "fake logger"

  context "on failure" do
    before do
      @weird_logfile_path = File.join(@current_dir, 'logfile.foobar')
    end

    it "returns falsy when file is not text or html" do
      Pidgin2Adium.parse(@weird_logfile_path, @aliases).should be_false
    end

    it "logs an error" do
      Pidgin2Adium.parse(@weird_logfile_path, @aliases).should be_false
      Pidgin2Adium.logger.should have_received(:error).with(regexp_matches(/No parser found/i))
    end

    it "gracefully handles nonexistent files" do
      Pidgin2Adium.parse("i_do_not_exist.html", @aliases).should be_false
      Pidgin2Adium.parse("i_do_not_exist.txt", @aliases).should be_false
    end
  end

  context "on success" do
    context "for a text file" do
      it "returns a LogFile instance" do
        result = Pidgin2Adium.parse(@text_logfile_path, @aliases)
        result.should be_instance_of(Pidgin2Adium::LogFile)
      end
    end

    context "for an htm file" do
      it "returns a LogFile instance" do
        result = Pidgin2Adium.parse(@htm_logfile_path, @aliases)
        result.should be_instance_of(Pidgin2Adium::LogFile)
      end
    end

    context "for an html file" do
      it "returns a LogFile instance" do
        result = Pidgin2Adium.parse(@html_logfile_path, @aliases)
        result.should be_instance_of(Pidgin2Adium::LogFile)
      end
    end
  end
end

describe Pidgin2Adium, "#parse_and_generate" do
  include_context "fake logger"

  before do
    # text logfile has screenname awesomeSN,
    # and html logfiles have screenname otherSN
    @text_output_file_path = File.join(@output_dir,
                                        "AIM.awesomesn",
                                        "BUDDY_PERSON",
                                        "BUDDY_PERSON (2006-12-21T22.36.06+00:00).chatlog",
                                        "BUDDY_PERSON (2006-12-21T22.36.06+00:00).xml")
    @htm_output_file_path = File.join(@output_dir,
                                      "AIM.otherSN",
                                      "aolsystemmsg",
                                      "aolsystemmsg (2008-01-15T07.14.45-0500).chatlog",
                                      "aolsystemmsg (2008-01-15T07.14.45-0500).xml")
    @html_output_file_path = @htm_output_file_path
  end

  describe "failure" do
    describe "when output_dir does not exist" do
      before do
        @opts = { :output_dir => @nonexistent_output_dir }
        FileUtils.rm_r(@nonexistent_output_dir, :force => true)
      end

      after do
        `chmod +w #{@current_dir}`
      end

      it "returns false when it can't create the output dir" do
        `chmod -w #{@current_dir}` # prevent creation of output_dir
        Pidgin2Adium.parse_and_generate(@text_logfile_path,
                                        @aliases,
                                        @opts).should be_false
      end
    end

    describe "when output_dir does exist" do
      before do
        @opts = { :output_dir => @output_dir }
      end

      describe "when file already exists" do
      #   describe "when :force is not set" do
      #     context "for a text file" do
      #       it "should return FILE_EXISTS" do
      #         FileUtils.mkdir_p(File.dirname(@text_output_file_path))
      #         File.new(@text_output_file_path, 'w').tap do |f|
      #           f.write('hi')
      #           f.close
      #         end
      #         Pidgin2Adium.parse_and_generate(@text_logfile_path,
      #                                         @aliases,
      #                                         @opts).should == Pidgin2Adium::FILE_EXISTS
      #       end
      #     end

      #     context "for an HTM file" do
      #       before do
      #         FileUtils.mkdir_p(File.dirname(@htm_output_file_path))
      #         File.new(@htm_output_file_path, 'w').close # create file
      #       end
      #       it "should return FILE_EXISTS" do
      #         Pidgin2Adium.parse_and_generate(@htm_logfile_path,
      #                                         @aliases,
      #                                         @opts).should == Pidgin2Adium::FILE_EXISTS
      #       end
      #     end

      #     context "for an HTML file" do
      #       before do
      #         FileUtils.mkdir_p(File.dirname(@html_output_file_path))
      #         File.new(@html_output_file_path, 'w').close # create file
      #       end
      #       it "should return FILE_EXISTS" do
      #         Pidgin2Adium.parse_and_generate(@html_logfile_path,
      #                                         @aliases,
      #                                         @opts).should == Pidgin2Adium::FILE_EXISTS
      #       end
      #     end
        # end
      end
    end
  end # failure

  describe "success" do
    describe "when output_dir does not exist" do
      before do
        @opts = { :output_dir => @nonexistent_output_dir }
        FileUtils.rm_r(@nonexistent_output_dir, :force => true)
      end

      context "for a text file" do
        specify { Pidgin2Adium.parse_and_generate(@text_logfile_path, @aliases, @opts).should be_true }
      end
      context "for an htm file" do
        specify { Pidgin2Adium.parse_and_generate(@htm_logfile_path, @aliases, @opts).should be_true }
      end
      context "for an html file" do
        specify { Pidgin2Adium.parse_and_generate(@html_logfile_path, @aliases, @opts).should be_true }
      end
    end

    describe "when output_dir does exist" do
      before do
        @opts = { :output_dir => @output_dir }
      end
      context "for a text file" do
        specify do
          Pidgin2Adium.parse_and_generate(@text_logfile_path,
                                          @aliases,
                                          @opts).should be_true
        end
      end
      context "for an htm file" do
        specify do
          Pidgin2Adium.parse_and_generate(@htm_logfile_path,
                                          @aliases,
                                          @opts).should be_true
        end
      end
      context "for an html file" do
        specify do
          Pidgin2Adium.parse_and_generate(@html_logfile_path,
                                          @aliases,
                                          @opts).should be_true
        end
      end
    end
  end # success
end
