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

  # Basic message with body text (as opposed to pure status messages, which
  # have no body).
  class XMLMessage < Message
    def initialize(sender, time, buddy_alias, body)
      super(sender, time, buddy_alias)
      @body = body
      @styled_body = '<div><span style="font-family: Helvetica; font-size: 12pt;">%s</span></div>' % @body
      normalize_body!()
    end
    attr_accessor :body

    def to_s
      return sprintf('<message sender="%s" time="%s" alias="%s">%s</message>' << "\n",
                     @sender, @time, @buddy_alias, @styled_body)
    end

    # Balances mismatched tags, normalizes body style, and fixes actions
    # so they are in Adium style (Pidgin uses "***Buddy waves at you", Adium uses
    # "*Buddy waves at you*").
    def normalize_body!
      normalize_body_entities!()
      # Fix mismatched tags. Yes, it's faster to do it per-message
      # than all at once.
      @body = Pidgin2Adium.balance_tags_c(@body)
      if @buddy_alias[0,3] == '***'
        # "***<alias>" is what pidgin sets as the alias for a /me action
        @buddy_alias.slice!(0,3)
        @body = '*' << @body << '*'
      end
    end

    # Escapes entities.
    def normalize_body_entities!
      # Convert '&' to '&amp;' only if it's not followed by an entity.
      @body.gsub!(/&(?!lt|gt|amp|quot|apos)/, '&amp;')
    end
  end # END XMLMessage class

  # An auto reply message.
  class AutoReplyMessage < XMLMessage
    def to_s
      return sprintf('<message sender="%s" time="%s" auto="true" alias="%s">%s</message>' << "\n",
                     @sender, @time, @buddy_alias, @styled_body)
    end
  end # END AutoReplyMessage class

  # A message saying e.g. "Blahblah has gone away."
  class StatusMessage < Message
    def initialize(sender, time, buddy_alias, status)
      super(sender, time, buddy_alias)
      @status = status
    end
    attr_accessor :status

    def to_s
      return sprintf('<status type="%s" sender="%s" time="%s" alias="%s"/>' << "\n", @status, @sender, @time, @buddy_alias)
    end
  end # END StatusMessage class

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
  end # END Event class
end
