module Pidgin2Adium
  class HtmlLogParser
    TIMESTAMP_REGEX = /\((?<timestamp>(?:\d{4}-\d{2}-\d{2} )?\d{1,2}:\d{1,2}:\d{1,2}(?: [AP]M)?)\)/

    def initialize(source_file_path, user_aliases)
      # @line_regex matches a line in an HTML log file other than the first.
      line_regex = /#{TIMESTAMP_REGEX} ?<b>(?<sn_or_alias>.+?) ?(?<auto_reply>&lt;AUTO-REPLY&gt;)?:?<\/b> ?(?<body>.+)<br ?\/>/o

      # @line_regex_status matches a status or event line.
      line_regex_status = /#{TIMESTAMP_REGEX} ?<b> (?<body>.+)<\/b><br ?\/>/o

      cleaner = Cleaners::HtmlCleaner

      @parser = BasicParser.new(source_file_path, user_aliases, line_regex,
        line_regex_status, cleaner)
    end

    def parse
      @parser.parse
    end
  end
end
