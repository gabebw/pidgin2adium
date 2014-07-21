module Pidgin2Adium
  class Runner
    def initialize(path_to_directory, options = {})
      @path_to_directory = path_to_directory
      @stdout = options.fetch(:stdout, STDOUT)
    end

    def run
      create_adium_logs_directory

      files_to_parse.each do |file_path|
        chat = Pipio::Chat.new(file_path)
        path = "#{adium_log_directory}/#{chat.service}.#{chat.my_screen_name}/#{chat.their_screen_name}/#{chat.their_screen_name} (#{chat.start_time_xmlschema}).chatlog/#{chat.their_screen_name} (#{chat.start_time_xmlschema}).xml"
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
      end

      @stdout.print "What are your aliases (comma-separated like Gabe,Gabe B-W)? > "
    end

    private

    def files_to_parse
      FileFinder.new(@path_to_directory).find
    end

    def create_adium_logs_directory
      FileUtils.mkdir_p(adium_log_directory)
    end

    def adium_log_directory
      File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/')
    end
  end
end
