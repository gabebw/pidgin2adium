# Author: Gabe Berke-Williams, 2008
#
# A ruby program to convert Pidgin log files to Adium log files, then place
# them in the Adium log directory.

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'fileutils'
require 'pidgin2adium/log_parser'

module Pidgin2Adium
  # Returned by LogFile.write_out if the output logfile already exists.
  FILE_EXISTS = 42
  ADIUM_LOG_DIR = File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') << '/'
  # These files/directories show up in Dir.entries()
  BAD_DIRS = %w{. .. .DS_Store Thumbs.db .system}
  VERSION = "3.0.1"
  # For displaying after we finish converting
  @@oops_messages = []
  @@error_messages = []

    def log_msg(str) #:nodoc:
      puts str.to_s
    end

    def oops(str) #:nodoc:
      @@oops_messages << str
      warn("Oops: #{str}")
    end

    def error(str) #:nodoc:
      @@error_messages << str
      warn("Error: #{str}")
    end

    #######################
    #So that we can use log_msg when calling delete_search_indexes() by itself
    module_function :log_msg, :oops, :error
    #######################

    # Parses the provided log.
    # Returns a LogFile instance or false if an error occurred.
    def parse(logfile_path, my_aliases)
      logfile_path = File.expand_path(logfile_path)
      ext = File.extname(logfile_path).sub('.', '').downcase

      if(ext == "html" || ext == "htm")
        parser = HtmlLogParser.new(logfile_path, my_aliases)
      elsif(ext == "txt")
        parser = TextLogParser.new(logfile_path, my_aliases)
      else
        error("Doing nothing, logfile is not a text or html file. Path: #{logfile_path}.")
        return false
      end

      return parser.parse()
    end

    # Parses the provided log and writes out the log in Adium format.
    # Returns:
    #  * true if it successfully converted and wrote out the log,
    #  * false if an error occurred, or
    #  * Pidgin2Adium::FILE_EXISTS if file already exists AND
    #    opts[:overwrite] = false.
    #
    # You can add options using the _opts_ hash, which can have the following
    # keys, all of which are optional:
    # * *overwrite*: If true, then overwrite even if log is found.
    #	Defaults to false.
    # * *output_dir*: The top-level dir to put the logs in.
    #   Logs under output_dir are still each in their own folders, etc.
    #   Defaults to Pidgin2Adium::ADIUM_LOG_DIR
    def parse_and_generate(logfile_path, my_aliases, opts = {})
      opts = {} unless opts.is_a?(Hash)
      overwrite = !!opts[:overwrite]
      if opts.key?(:output_dir)
        output_dir = opts[:output_dir]
      else
        output_dir = ADIUM_LOG_DIR
      end

      unless File.directory?(output_dir)
        puts "Output log directory (#{output_dir}) does not exist or is not a directory."
        begin
          FileUtils.mkdir_p(output_dir)
        rescue Errno::EACCES
          puts "Permission denied, could not create output directory (#{output_dir})"
          return false
        end
      end

      logfile_obj = parse(logfile_path, my_aliases)
      return false if logfile_obj == false
      dest_file_path = logfile_obj.write_out(overwrite, output_dir)
      if dest_file_path == false
        error("Successfully parsed file, but failed to write it out. Path: #{logfile_path}.")
        return false
      elsif dest_file_path == FILE_EXISTS
        log_msg("File already exists.")
        return FILE_EXISTS
      else
        log_msg("Output to: #{dest_file_path}")
        return true
      end
    end

    # Newly-converted logs are viewable in the Adium Chat Transcript
    # Viewer, but are not indexed, so a search of the logs doesn't give
    # results from the converted logs. To fix this, we delete the cached log
    # indexes, which forces Adium to re-index.
    #
    # Note: This function is run by LogConverter after converting all of its
    # files.  LogFile.write_out intentionally does _not_ run it in order to
    # allow for batch-processing of files. Thus, you will probably want to run
    # Pidgin2Adium.delete_search_indexes after running LogFile.write_out in
    # your own scripts.
    def delete_search_indexes()
      log_msg "Deleting log search indexes in order to force re-indexing of imported logs..."
      dirty_file = File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
      log_index_file = File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
      [dirty_file, log_index_file].each do |f|
        if File.exist?(f)
          if File.writable?(f)
            File.delete(f)
          else
            error("File exists but is not writable. Please delete it yourself: #{f}")
          end
        end
      end
      log_msg "...done."
      log_msg "When you next start the Adium Chat Transcript Viewer, it will re-index the logs, which may take a while."
    end

    module_function :parse, :parse_and_generate, :delete_search_indexes
end
