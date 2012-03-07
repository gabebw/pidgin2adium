module Pidgin2Adium
  # An auto reply message.
  class AutoReplyMessage < XMLMessage
    def to_s
      %(<message sender="#{sender}s" time="#{@time}s" auto="true" alias="#{@buddy_alias}">#{@styled_body}</message>\n)
    end
  end
end
