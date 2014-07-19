module Pidgin2Adium
  class ParserFactory
    PARSER_FOR_EXTENSION = {
      "html" => HtmlLogParser,
      "htm" => HtmlLogParser,
      "txt" => TextLogParser
    }

    def initialize(logfile_path, aliases)
      @logfile_path = logfile_path
      @aliases = aliases
    end

    def parser
      parser_class.new(@logfile_path, @aliases)
    end

    private

    def parser_class
      PARSER_FOR_EXTENSION.fetch(extension, NullParser)
    end

    def extension
      extension_with_leading_period[1..-1]
    end

    def extension_with_leading_period
      File.extname(@logfile_path).downcase
    end
  end
end
