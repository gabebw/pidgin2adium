# Author: Gabe Berke-Williams, 2008
#
# A ruby program to convert Pidgin log files to Adium log files, then place
# them in the Adium log directory.

require 'fileutils'
require 'date'
require 'time'

require 'pidgin2adium/version'
require 'pidgin2adium/parsers/all'
require 'pidgin2adium/tag_balancer'
require 'pidgin2adium/logger'
require 'pidgin2adium/parser_factory'
require 'pidgin2adium/time_parser'
require 'pidgin2adium/metadata'
require 'pidgin2adium/first_line_parser'

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

  def self.log(str)
    Pidgin2Adium.logger.log(str)
  end

  def self.warn(str)
    Pidgin2Adium.logger.warn(str)
  end

  def self.error(str)
    Pidgin2Adium.logger.error(str)
  end

  # Parses the provided log.
  # Returns a LogFile instance or false if an error occurred.
  def self.parse(logfile_path, my_aliases)
    logfile_path = File.expand_path(logfile_path)

    factory =  ParserFactory.new(my_aliases)
    parser = factory.parser_for(logfile_path)

    if parser
      parser.parse
    end
  end
end
