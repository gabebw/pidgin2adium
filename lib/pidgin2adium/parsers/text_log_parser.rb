module Pidgin2Adium
  class TextLogParser < BasicParser
    TIMESTAMP_REGEX = '\((\d{1,2}:\d{1,2}:\d{1,2})\)'

    def initialize(source_file_path, user_aliases)
      super(source_file_path, user_aliases)

      # @line_regex matches a line in a TXT log file other than the first
      # @line_regex matchdata:
      # 0: timestamp
      # 1: screen name or alias, if alias set
      # 2: "<AUTO-REPLY>" or nil
      # 3: message body
      @line_regex = /#{TIMESTAMP_REGEX} (.*?) ?(<AUTO-REPLY>)?: (.*)/o
      # @line_regex_status matches a status line
      # @line_regex_status matchdata:
      # 0: timestamp
      # 1: status message
      @line_regex_status = /#{TIMESTAMP_REGEX} ([^:]+)/o
    end

    def cleanup(text)
      text.tr!("\r", '')
      # Escape entities since this will be in XML
      text.gsub!('&', '&amp;') # escape '&' first
      text.gsub!('<', '&lt;')
      text.gsub!('>', '&gt;')
      text.gsub!('"', '&quot;')
      text.gsub!("'", '&apos;')
      # Replace newlines with "<br/>" unless they end a chat line.
      # Add the <br/> after converting to &lt; etc so we
      # don't escape the tag.
      text.gsub!(/\n(?!(#{TIMESTAMP_REGEX}|\Z))/, '<br/>')
      text
    end
  end
end
