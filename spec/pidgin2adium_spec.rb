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

  it { should delegate(:error).to(:logger).with_arguments('hi') }
  it { should delegate(:warn).to(:logger).with_arguments('hi') }
  it { should delegate(:log).to(:logger).with_arguments('hi') }

  describe "#delete_search_indexes" do
    before do
      @dirty_file = File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
      @log_index_file = File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
    end

    describe "when search indices exist" do
      it "deletes the search indices" do
        stub_deletion
        Pidgin2Adium.delete_search_indexes
        assert_deleted(@dirty_file)
        assert_deleted(@log_index_file)
      end

      def stub_deletion
        FileUtils.stubs(:rm_f)
      end

      def assert_deleted(path_to_file)
        FileUtils.should have_received(:rm_f).with(path_to_file)
      end
    end
  end
end

describe Pidgin2Adium, "#parse" do
  include_context "fake logger"
  let(:aliases) { '' }

  context "on failure" do
    before do
      @weird_logfile_path = File.join(@current_dir, 'logfile.foobar')
    end

    it "returns falsy when file is not text or html" do
      Pidgin2Adium.parse(@weird_logfile_path, aliases).should be_false
    end

    it "logs an error" do
      Pidgin2Adium.parse(@weird_logfile_path, aliases).should be_false
      Pidgin2Adium.logger.should have_received(:error).with(regexp_matches(/No parser found/i))
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

describe Pidgin2Adium, "#parse_and_generate" do
  include_context "fake logger"
  let(:aliases) { '' }

  before do
    # text logfile has screenname awesomeSN,
    # and html logfiles have screenname otherSN
    @text_output_file_path = File.join(@output_dir,
                                        "AIM.awesomesn",
                                        "BUDDY_PERSON",
                                        "BUDDY_PERSON (2006-12-21T22:36:06+00:00).chatlog",
                                        "BUDDY_PERSON (2006-12-21T22:36:06+00:00).xml")
    @htm_output_file_path = File.join(@output_dir,
                                      "AIM.otherSN",
                                      "aolsystemmsg",
                                      "aolsystemmsg (2008-01-15T07:14:45EST).chatlog",
                                      "aolsystemmsg (2008-01-15T07:14:45EST).xml")
    @html_output_file_path = File.join(@output_dir,
                                      "AIM.otherSN",
                                      "aolsystemmsg",
                                      "aolsystemmsg (2008-01-15T07:14:45EST).chatlog",
                                      "aolsystemmsg (2008-01-15T07:14:45EST).xml")
    @nonexistent_output_dir = File.join(@current_dir, "nonexistent_output_dir/")
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
        result = Pidgin2Adium.parse_and_generate(create_chat_file('log.txt'), '', @opts)
        result.should be_false
      end
    end

    describe "when output_dir does exist" do
      before do
        @opts = { :output_dir => @output_dir }
      end

      describe "when file already exists" do
        describe "when :force is not set" do
          context "for a text file" do
            it "should return FILE_EXISTS" do
              FileUtils.mkdir_p(File.dirname(@text_output_file_path))
              File.new(@text_output_file_path, 'w').close
              Pidgin2Adium.parse_and_generate(@text_logfile_path,
                                              aliases,
                                              @opts).should == Pidgin2Adium::FILE_EXISTS
            end
          end

          context "for an HTM file" do
            before do
              FileUtils.mkdir_p(File.dirname(@htm_output_file_path))
              File.new(@htm_output_file_path, 'w').close # create file
            end
            it "should return FILE_EXISTS" do
              Pidgin2Adium.parse_and_generate(@htm_logfile_path,
                                              aliases,
                                              @opts).should == Pidgin2Adium::FILE_EXISTS
            end
          end

          context "for an HTML file" do
            before do
              FileUtils.mkdir_p(File.dirname(@html_output_file_path))
              File.new(@html_output_file_path, 'w').close # create file
            end
            it "should return FILE_EXISTS" do
              Pidgin2Adium.parse_and_generate(@html_logfile_path,
                                              aliases,
                                              @opts).should == Pidgin2Adium::FILE_EXISTS
            end
          end
        end
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
        it "returns true" do
          result = Pidgin2Adium.parse_and_generate(create_chat_file('log.txt'), aliases, @opts)
          result.should be_true
        end
      end

      context "for an htm file" do
        it "returns true" do
          result = Pidgin2Adium.parse_and_generate(create_chat_file('log.htm'), aliases, @opts)
          result.should be_true
        end
      end

      context "for an html file" do
        it "returns true" do
          result = Pidgin2Adium.parse_and_generate(create_chat_file('log.html'), aliases, @opts)
          result.should be_true
        end
      end
    end

    describe "when output_dir does exist" do
      before do
        @opts = { :output_dir => @output_dir }
      end

      context "for a text file" do
        it "returns true" do
          result = Pidgin2Adium.parse_and_generate(create_chat_file('log.txt'), aliases, @opts)
          result.should be_true
        end
      end

      context "for an htm file" do
        it "returns true" do
          result = Pidgin2Adium.parse_and_generate(create_chat_file('log.htm'), aliases, @opts)
          result.should be_true
        end
      end

      context "for an html file" do
        it "returns true" do
          result = Pidgin2Adium.parse_and_generate(create_chat_file('log.html'), aliases, @opts)
          result.should be_true
        end
      end
    end
  end # success
end
