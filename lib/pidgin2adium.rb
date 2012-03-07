# Author: Gabe Berke-Williams, 2008
#
# A ruby program to convert Pidgin log files to Adium log files, then place
# them in the Adium log directory.

require 'fileutils'
require 'time'

require 'pidgin2adium/version'
require 'pidgin2adium/parsers/all'
require 'pidgin2adium/tag_balancer'
require 'pidgin2adium/logger'
require 'pidgin2adium/parser_factory'
require 'pidgin2adium/time_parser'
require 'pidgin2adium/metadata'

module Pidgin2Adium
  # Returned by LogFile.write_out if the output logfile already exists.
  FILE_EXISTS = 42
  ADIUM_LOG_DIR = File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') << '/'
  # These files/directories show up in Dir.entries()
  BAD_DIRS = %w{. .. .DS_Store Thumbs.db .system}

  def self.logger
    @@logger ||= Pidgin2Adium::Logger.new
  end

  def self.logger=(new_logger)
    @@logger = new_logger
  end

  def self.log(str) #:nodoc:
    Pidgin2Adium.logger.log(str)
  end

  def self.oops(str) #:nodoc:
    Pidgin2Adium.logger.oops(str)
  end

  def self.error(str) #:nodoc:
    Pidgin2Adium.logger.error(str)
  end

  # Parses the provided log.
  # Returns a LogFile instance or false if an error occurred.
  def self.parse(logfile_path, my_aliases, force_conversion = false)
    logfile_path = File.expand_path(logfile_path)

    factory =  ParserFactory.new(my_aliases, force_conversion)
    parser = factory.parser_for(logfile_path)

    if parser
      parser.parse
    else
      Pidgin2Adium.error("No parser found for the given path (is it an HTML or text file?):#{logfile_path}")
      false
    end
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
  def self.parse_and_generate(logfile_path, my_aliases, opts = {})
    opts = {} unless opts.is_a?(Hash)
    overwrite = !!opts[:overwrite]
    force_conversion = opts[:force_conversion]

    if opts.key?(:output_dir)
      output_dir = opts[:output_dir]
    else
      output_dir = ADIUM_LOG_DIR
    end

    unless File.directory?(output_dir)
      error("Output log directory (#{output_dir}) does not exist or is not a directory.")
      begin
        FileUtils.mkdir_p(output_dir)
      rescue Errno::EACCES
        error("Permission denied, could not create output directory (#{output_dir})")
        return false
      end
    end

    logfile_obj = parse(logfile_path, my_aliases, force_conversion)
    return false if logfile_obj == false
    dest_file_path = logfile_obj.write_out(overwrite, output_dir)

    if dest_file_path == false
      error("Successfully parsed file, but failed to write it out. Path: #{logfile_path}.")
      return false
    elsif dest_file_path == FILE_EXISTS
      log("File already exists.")
      return FILE_EXISTS
    else
      log("Output to: #{dest_file_path}")
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
  def self.delete_search_indexes
    log "Deleting log search indexes in order to force re-indexing of imported logs..."
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
    log "...done."
    log "When you next start the Adium Chat Transcript Viewer, it will re-index the logs, which may take a while."
  end
end
