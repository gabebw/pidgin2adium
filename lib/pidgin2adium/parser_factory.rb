module Pidgin2Adium
  class ParserFactory
    def initialize(aliases)
      @aliases = aliases
    end

    def parser_for(logfile_path)
      case logfile_path
      when /\.html?$/i
        HtmlLogParser.new(logfile_path, @aliases)
      when /\.txt$/i
        TextLogParser.new(logfile_path, @aliases)
      end
    end
  end
end
