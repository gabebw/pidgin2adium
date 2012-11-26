module Pidgin2Adium
  # The parsed chat.
  class Chat
    include Enumerable

    def initialize(lines)
      @lines = lines
    end

    attr_reader :lines

    # The lines joined together
    def to_s
      map(&:to_s).join
    end

    # Iterate over each Message.
    def each(&block)
      @lines.each(&block)
    end
  end
end
