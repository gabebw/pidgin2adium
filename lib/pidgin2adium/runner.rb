module Pidgin2Adium
  class Runner
    def initialize(path_to_directory)
      @path_to_directory = path_to_directory
    end

    def run
      files_to_parse.each do |file_path|
        AdiumChatFileCreator.new(file_path).create
      end
    end

    private

    def files_to_parse
      FileFinder.new(@path_to_directory).find
    end
  end
end
