module Pidgin2Adium
  class ParserFactory
    def initialize(logfile_path, aliases)
      @logfile_path = logfile_path
      @aliases = aliases
    end

    def parser
      parser_class.new(@logfile_path, @aliases)
    end

    private

    def parser_class
      case @logfile_path
      when /\.html?$/i
        HtmlLogParser
      when /\.txt$/i
        TextLogParser
      else
        NullParser
      end
    end
  end
end
