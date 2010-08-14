# The Message class and its subclasses, each used for holding one line of a
# chat.

module Pidgin2Adium
  # A holding object for each line of the chat. It is subclassed as
  # appropriate (eg AutoReplyMessage). Each subclass (but not Message
  # itself) has its own to_s which prints out its information in a format
  # appropriate for putting in an Adium log file.
  # Subclasses: XMLMessage, AutoReplyMessage, StatusMessage, Event.
  class Message
    def initialize(sender, time, buddy_alias)
      # The sender's screen name
      @sender = sender
      # The time the message was sent, in Adium format (e.g.
      # "2008-10-05T22:26:20-0800")
      @time = time
      # The receiver's alias (NOT screen name)
      @buddy_alias = buddy_alias
    end
    attr_accessor :sender, :time, :buddy_alias
  end
end
