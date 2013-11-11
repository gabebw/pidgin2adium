require 'nokogiri'
require 'time'
require 'pidgin2adium/html_log_parser'
require 'pidgin2adium/message'

module Pidgin2Adium
  def self.parse(path_to_chatlog)
    if File.exist?(path_to_chatlog)
      Pidgin2Adium::HtmlLogParser.new(path_to_chatlog).parse
    end
  end
end
