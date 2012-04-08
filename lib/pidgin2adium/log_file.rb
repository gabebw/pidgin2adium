module Pidgin2Adium
  # A holding object for the parsed chat. LogFile#each will
  # iterate over each Message in the chat.
  class LogFile
    include Enumerable

    def initialize(chat_lines)
      @chat_lines = chat_lines
    end

    attr_reader :chat_lines

    # Returns contents of log file
    def to_s
      map(&:to_s).join
    end

    def each(&block)
      @chat_lines.each(&block)
    end
  end
end
