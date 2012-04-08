module Pidgin2Adium
  # Pidgin does not have Events, but Adium does. Pidgin mostly uses system
  # messages to display what Adium calls events. These include sending a file,
  # starting a Direct IM connection, or an error in chat.
  class Event < XMLMessage
    def initialize(sender_screen_name, time, sender_alias, body, event_type)
      super(sender_screen_name, time, sender_alias, body)
      @event_type = event_type
    end

    attr_reader :event_type

    def to_s
      %(<event type="#{@event_type}" sender="#{@sender_screen_name}" time="#{@time}" alias="#{@sender_alias}">#{@styled_body}</event>)
    end
  end
end
