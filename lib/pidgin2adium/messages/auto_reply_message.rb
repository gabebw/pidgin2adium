# The Message class's subclasses, each used for holding one line of a chat.

module Pidgin2Adium
  # An auto reply message.
  class AutoReplyMessage < XMLMessage
    def to_s
      return sprintf('<message sender="%s" time="%s" auto="true" alias="%s">%s</message>' << "\n",
                     @sender, @time, @buddy_alias, @styled_body)
    end
  end
end
