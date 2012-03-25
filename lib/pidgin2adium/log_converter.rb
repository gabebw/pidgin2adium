require 'pidgin2adium'

module Pidgin2Adium
  # An easy way to batch-process a directory. Used by the pidgin2adium
  # command-line script.
  class LogConverter
    # You can add options using the _opts_ hash, which can have the
    # following keys, all of which are optional:
    # * *output_dir*: The top-level dir to put the logs in.
    #   Logs under output_dir are still each in their own folders, etc.
    #   Defaults to Pidgin2Adium::ADIUM_LOG_DIR
    def initialize(pidgin_log_dir, aliases, opts = {})
      # parse_and_generate will process it for us
      @opts = opts

      @pidgin_log_dir = File.expand_path(pidgin_log_dir)
      @my_aliases = aliases

      unless File.directory?(@pidgin_log_dir)
        msg = "Source directory #{@pidgin_log_dir} does not exist or is not a directory."
        Pidgin2Adium.error(msg)

        # ENOENT automatically prepends "No such file or directory - " to
        # its initializer's arguments
        raise Errno::ENOENT.new("source directory #{@pidgin_log_dir}")
      end
    end

    # Runs Pidgin2Adium::parse_and_generate on every log file in directory
    # provided in new, then deletes Adium's search indexes to force
    # it to rescan logs on startup.
    def start
      Pidgin2Adium.log "Begin converting."
      begin
        files_path = get_all_chat_files()
      rescue Errno::EACCES => bang
        Pidgin2Adium.error("Sorry, permission denied for getting Pidgin chat files from #{@pidgin_log_dir}.")
        Pidgin2Adium.error("Details: #{bang.message}")
        raise bang
      end

      total_files = files_path.size
      total_successes = 0
      Pidgin2Adium.log("#{total_files} files to convert.")
      files_path.each_with_index do |file_name, i|
        progress = i + 1
        Pidgin2Adium.log("[#{progress}/#{total_files}] Converting #{file_name}...")
        result = Pidgin2Adium.parse_and_generate(file_name, @my_aliases, @opts)
        total_successes += 1 if result == true
      end

      Pidgin2Adium.delete_search_indexes

      Pidgin2Adium.log "Finished converting! Converted #{total_successes} files of #{total_files} total."
      Pidgin2Adium.logger.flush_warnings_and_errors
    end

    def get_all_chat_files
      Dir.glob("#{@pidgin_log_dir}/**/*.{htm,html,txt}") - BAD_DIRS
    end
  end
end
