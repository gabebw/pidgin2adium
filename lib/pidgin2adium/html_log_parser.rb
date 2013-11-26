module Pidgin2Adium
  class HtmlLogParser
    # System: FF0000
    SELECTOR = 'font[color^="#"]'
    METADATA_RE = /^Conversation with (?<their_screen_name>.*) at [^o]+ on (?<my_screen_name>.*) \(aim\)$/
    COLOR_OF_MY_MESSAGES = '#16569E'
    COLOR_OF_THEIR_MESSAGES = '#A82F2F'

    def initialize(path_to_log)
      @doc = Nokogiri(open(path_to_log))
    end

    def parse
      @doc.css(SELECTOR).map do |node|
        timestamp_and_alias = node.text
        if node.next.next.name == 'br'
          body = node.next.text
        else
          string = node.next.to_s
          current = node.next.next
          while current.name != 'br'
            string << current.to_s
            current = current.next
          end
          body = string
        end

        matches = timestamp_and_alias.match(/\((?<timestamp>.*)\) (?<sender_alias>.*):$/)

        Message.new(
          time: Time.parse(matches[:timestamp]),
          sender_alias: matches[:sender_alias],
          sender_screen_name: screen_name_based_on_color(node[:color]),
          body: body.strip
        )
      end
    end

    private

    def screen_name_based_on_color(color)
      if color == COLOR_OF_MY_MESSAGES
        metadata[:my_screen_name]
      elsif color == COLOR_OF_THEIR_MESSAGES
        metadata[:their_screen_name]
      end
    end

    def metadata
      @metadata ||= @doc.at('head').text.match(METADATA_RE)
    end
  end
end
