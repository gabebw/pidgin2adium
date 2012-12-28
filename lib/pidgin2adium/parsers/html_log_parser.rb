module Pidgin2Adium
  class HtmlLogParser
    TIMESTAMP_REGEX = '\(((?:\d{4}-\d{2}-\d{2} )?\d{1,2}:\d{1,2}:\d{1,2}(?: [AP]M)?)\)'

    def initialize(source_file_path, user_aliases)
      # @line_regex matches a line in an HTML log file other than the
      # first time matches on either "2008-11-17 14:12" or "14:12"
      # @line_regex match obj:
      # 0: timestamp, extended or not
      # 1: screen name or alias, if alias set
      # 2: "&lt;AUTO-REPLY&gt;" or nil
      # 3: message body
      # The ":" is optional to allow for strings like "(17:12:21) <b>***Gabe B-W</b> is confused<br/>"
      line_regex = /#{TIMESTAMP_REGEX} ?<b>(.+?) ?(&lt;AUTO-REPLY&gt;)?:?<\/b> ?(.+)<br ?\/>/o

      # @line_regex_status matches a status line
      # @line_regex_status match obj:
      # 0: timestamp
      # 1: status message
      line_regex_status = /#{TIMESTAMP_REGEX} ?<b> (.+)<\/b><br ?\/>/o

      cleaner = Cleaners::HtmlCleaner

      @parser = BasicParser.new(source_file_path, user_aliases, line_regex,
        line_regex_status, cleaner)
    end

    def parse
      @parser.parse
    end
  end
end
