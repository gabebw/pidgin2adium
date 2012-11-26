module Pidgin2Adium
  module Cleaners
    class TextCleaner
      def self.clean(line)
        # Escape entities since this will be in XML
        line.gsub("\r", '').
          gsub('&', '&amp;').
          gsub('<', '&lt;').
          gsub('>', '&gt;').
          gsub('"', '&quot;').
          gsub("'", '&apos;')
      end
    end
  end
end
