require 'date'
require 'time'

require 'pidgin2adium/version'
require 'pidgin2adium/chat'
require 'pidgin2adium/tag_balancer'
require 'pidgin2adium/parser_factory'
require 'pidgin2adium/time_parser'
require 'pidgin2adium/metadata'
require 'pidgin2adium/metadata_parser'
require 'pidgin2adium/alias_registry'
require 'pidgin2adium/file_reader'
require 'pidgin2adium/parsers/null_parser'
require 'pidgin2adium/parsers/basic_parser'
require 'pidgin2adium/parsers/text_log_parser'
require 'pidgin2adium/parsers/html_log_parser'
require 'pidgin2adium/messages/message'
require 'pidgin2adium/messages/xml_message'
require 'pidgin2adium/messages/auto_reply_message'
require 'pidgin2adium/messages/event'
require 'pidgin2adium/messages/status_message'
require 'pidgin2adium/cleaners/html_cleaner'
require 'pidgin2adium/cleaners/text_cleaner'

module Pidgin2Adium
  # Parses the log at the given path into a Chat.
  def self.parse(logfile_path, sender_aliases)
    factory = ParserFactory.new(sender_aliases)
    parser = factory.parser_for(File.expand_path(logfile_path))
    parser.parse
  end
end
