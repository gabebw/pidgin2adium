module Pidgin2Adium
  # A holding object for the result of LogParser.parse.  It makes the
  # instance variable @chat_lines available, which is an array of Message
  # subclass instances (XMLMessage, Event, etc.)
  # Here is a list of the instance variables for each class in @chat_lines:
  #
  # <b>All of these variables are read/write.</b>
  # All::		 sender, time, buddy_alias
  # XMLMessage::	 body
  # AutoReplyMessage:: body
  # Event::		 body, event_type
  # StatusMessage::	 status
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
