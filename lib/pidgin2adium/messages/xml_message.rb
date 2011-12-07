module Pidgin2Adium
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
      @body = Pidgin2Adium::TagBalancer.new(@body).balance
      if @buddy_alias[0,3] == '***'
        # "***<alias>" is what pidgin sets as the alias for a /me action
        @buddy_alias.slice!(0,3)
        @body = '*' << @body << '*'
      end
    end

    # Escapes all entities in @body except for "&lt;", "&gt;", "&amp;", "&quot;",
    # and "&apos;".
    def normalize_body_entities!
      # Convert '&' to '&amp;' only if it's not followed by an entity.
      @body.gsub!(/&(?!lt|gt|amp|quot|apos)/, '&amp;')
    end
  end
end
