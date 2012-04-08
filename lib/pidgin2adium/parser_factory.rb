module Pidgin2Adium
  class ParserFactory
    def initialize(aliases)
      @aliases = aliases
    end

    def parser_for(logfile_path)
      parser_class = case logfile_path
                     when /\.html?$/i
                       HtmlLogParser
                     when /\.txt$/i
                       TextLogParser
                     else
                       NullParser
                     end

      parser_class.new(logfile_path, @aliases)
    end
  end
end
