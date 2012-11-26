module Pidgin2Adium
  class TextLogParser < BasicParser
    TIMESTAMP_REGEX = '\((\d{1,2}:\d{1,2}:\d{1,2})\)'

    def initialize(source_file_path, user_aliases)
      super(source_file_path, user_aliases)

      # @line_regex matches a line in a TXT log file other than the first
      # @line_regex matchdata:
      # 0: timestamp
      # 1: screen name or alias, if alias set
      # 2: "<AUTO-REPLY>" or nil
      # 3: message body
      @line_regex = /#{TIMESTAMP_REGEX} (.*?) ?(<AUTO-REPLY>)?: (.*)/o
      # @line_regex_status matches a status line
      # @line_regex_status matchdata:
      # 0: timestamp
      # 1: status message
      @line_regex_status = /#{TIMESTAMP_REGEX} ([^:]+)/o

      @file_reader = FileReader.new(source_file_path, Cleaners::TextCleaner)
    end
  end
end
