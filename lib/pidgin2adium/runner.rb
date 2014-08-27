module Pidgin2Adium
  class Runner
    ADIUM_LOG_DIRECTORY = Pathname.new(File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/'))

    def initialize(path_to_input_directory, aliases, output_directory = ADIUM_LOG_DIRECTORY)
      @path_to_input_directory = path_to_input_directory
      @aliases = aliases
      @output_directory = output_directory
    end

    def run
      files_to_parse.each do |file_path|
        success = AdiumChatFileCreator.new(file_path, @aliases, @output_directory).create
        if success
          $stdout.print "."
        else
          $stderr.puts "\n!! Could not parse #{file_path}"
        end
      end
    end

    private

    def files_to_parse
      FileFinder.new(@path_to_input_directory).find
    end
  end
end
