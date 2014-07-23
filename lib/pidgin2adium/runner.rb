module Pidgin2Adium
  ADIUM_LOG_DIRECTORY = Pathname.new(File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/'))

  class Runner
    def initialize(path_to_directory)
      @path_to_directory = path_to_directory
    end

    def run
      create_adium_logs_directory

      files_to_parse.each do |file_path|
        AdiumChatFileCreator.new(file_path).create
      end
    end

    private

    def files_to_parse
      FileFinder.new(@path_to_directory).find
    end

    def create_adium_logs_directory
      FileUtils.mkdir_p(ADIUM_LOG_DIRECTORY)
    end
  end
end
