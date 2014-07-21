module Pidgin2Adium
  ADIUM_LOG_DIRECTORY = Pathname.new(File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/'))

  class Runner
    def initialize(path_to_directory)
      @path_to_directory = path_to_directory
    end

    def run
      create_adium_logs_directory

      files_to_parse.each do |file_path|
        chat = Pipio::Chat.new(file_path)
        path = ADIUM_LOG_DIRECTORY.join(
          "#{chat.service}.#{chat.my_screen_name}",
          chat.their_screen_name,
          "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).chatlog",
          "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).xml"
        )
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
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
