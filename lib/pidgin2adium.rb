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
require 'pidgin2adium/parser_factory'
require 'pidgin2adium/time_parser'
require 'pidgin2adium/metadata'
require 'pidgin2adium/first_line_parser'

module Pidgin2Adium
  # Parses the provided log.
  # Returns a LogFile instance or false if an error occurred.
  def self.parse(logfile_path, my_aliases)
    logfile_path = File.expand_path(logfile_path)

    factory =  ParserFactory.new(my_aliases)
    parser = factory.parser_for(logfile_path)
    parser.parse
  end
end
