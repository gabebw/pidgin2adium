module Pidgin2Adium
  class TextLogParser
    TIMESTAMP_REGEX = '\((\d{1,2}:\d{1,2}:\d{1,2})\)'

    def initialize(source_file_path, user_aliases)
      # @line_regex matches a line in a TXT log file other than the first
      # @line_regex matchdata:
      # 0: timestamp
      # 1: screen name or alias, if alias set
      # 2: "<AUTO-REPLY>" or nil
      # 3: message body
      line_regex = /#{TIMESTAMP_REGEX} (.*?) ?(<AUTO-REPLY>)?: (.*)/o
      # @line_regex_status matches a status line
      # @line_regex_status matchdata:
      # 0: timestamp
      # 1: status message
      line_regex_status = /#{TIMESTAMP_REGEX} ([^:]+)/o

      cleaner = Cleaners::TextCleaner

      @parser = BasicParser.new(source_file_path, user_aliases, line_regex,
        line_regex_status, cleaner)
    end

    def parse
      @parser.parse
    end
  end
end
