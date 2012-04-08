module Pidgin2Adium
  class ParserFactory
    def initialize(aliases, force_conversion)
      @aliases = aliases
      @force_conversion = force_conversion
    end

    def parser_for(logfile_path)
      case logfile_path
      when /\.html?$/i
        HtmlLogParser.new(logfile_path, @aliases, @force_conversion)
      when /\.txt$/i
        TextLogParser.new(logfile_path, @aliases, @force_conversion)
      end
    end
  end
end
