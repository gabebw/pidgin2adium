module Pidgin2Adium
  class Runner
    def initialize(path_to_file, options = {})
      @stdout = options.fetch(:stdout, STDOUT)
    end

    def run
      create_adium_logs_directory
      @stdout.print "What are your aliases (comma-separated like Gabe,Gabe B-W)? > "
    end

    private

    def create_adium_logs_directory
      FileUtils.mkdir_p(adium_log_directory)
    end

    def adium_log_directory
      File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/')
    end
  end
end

