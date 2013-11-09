module Pidgin2Adium
  class TextLogParser
    TIMESTAMP_REGEX = '\((?<timestamp>\d{1,2}:\d{1,2}:\d{1,2})\)'

    def initialize(source_file_path, user_aliases)
      # @line_regex matches a line in a text log file other than the first.
      line_regex = /#{TIMESTAMP_REGEX} (?<sn_or_alias>.*?) ?(?<auto_reply><AUTO-REPLY>)?: (?<body>.*)/o
      # @line_regex_status matches a status or event line.
      line_regex_status = /#{TIMESTAMP_REGEX} (?<body>[^:]+)/o

      cleaner = Cleaners::TextCleaner

      @parser = BasicParser.new(source_file_path, user_aliases, line_regex,
        line_regex_status, cleaner)
    end

    def parse
      @parser.parse
    end
  end
end
