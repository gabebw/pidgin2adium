module Pidgin2Adium
  # Pidgin does not have Events, but Adium does. Pidgin mostly uses system
  # messages to display what Adium calls events. These include sending a file,
  # starting a Direct IM connection, or an error in chat.
  class Event < XMLMessage
    def initialize(sender, time, buddy_alias, body, event_type)
      super(sender, time, buddy_alias, body)
      @event_type = event_type
    end

    attr_reader :event_type

    def to_s
      %(<event type="#{@event_type}" sender="#{@sender}" time="#{@time}" alias="#{@buddy_alias}">#{@styled_body}</event>)
    end
  end
end
