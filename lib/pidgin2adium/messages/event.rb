module Pidgin2Adium
  # Pidgin does not have Events, but Adium does. Pidgin mostly uses system
  # messages to display what Adium calls events. These include sending a file,
  # starting a Direct IM connection, or an error in chat.
  class Event < XMLMessage
    def initialize(sender, time, buddy_alias, body, event_type)
      super(sender, time, buddy_alias, body)
      @event_type = event_type
    end
    attr_accessor :event_type

    def to_s
      return sprintf('<event type="%s" sender="%s" time="%s" alias="%s">%s</event>',
                     @event_type, @sender, @time, @buddy_alias, @styled_body)
    end
  end
end
