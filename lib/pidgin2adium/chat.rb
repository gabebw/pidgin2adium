module Pidgin2Adium
  # The container object for each line of a parsed chat. It includes the
  # Enumerable module, so each/map/reject etc all work.
  class Chat
    include Enumerable

    def initialize(lines, their_screen_name, start_time)
      @lines = lines
      @their_screen_name = their_screen_name
      @start_time_xmlschema = start_time.xmlschema
    end

    attr_reader :lines, :their_screen_name, :start_time_xmlschema

    def to_s
      map(&:to_s).join
    end

    # Iterate over each Message.
    def each(&block)
      @lines.each(&block)
    end
  end
end
