module Pidgin2Adium
  # Basic message with body text (as opposed to pure status messages, which
  # have no body).
  class XMLMessage < Message
    def initialize(sender_screen_name, time, sender_alias, body)
      super(sender_screen_name, time, sender_alias)
      @body = normalize(body)
      @styled_body = %(<div><span style="font-family: Helvetica; font-size: 12pt;">#{@body}</span></div>)
    end

    attr_reader :body

    def to_s
      %(<message sender="#{@sender_screen_name}" time="#{adium_formatted_time}" alias="#{@sender_alias}">#{@styled_body}</message>\n)
    end

    private

    # Balances mismatched tags, normalizes body style, and fixes actions
    # so they are in Adium style (Pidgin uses "***Buddy waves at you", Adium uses
    # "*Buddy waves at you*").
    def normalize(string)
      new_body = normalize_entities(string)
      # Fix mismatched tags. Yes, it's faster to do it per-message
      # than all at once.
      new_body = Pidgin2Adium::TagBalancer.new(new_body).balance
      if @sender_alias[0,3] == '***'
        # "***<alias>" is what pidgin sets as the alias for a /me action
        @sender_alias.slice!(0,3)
        new_body = "*#{new_body}*"
      end

      new_body
    end

    # Escapes all entities in string except for "&lt;", "&gt;", "&amp;", "&quot;",
    # and "&apos;".
    def normalize_entities(string)
      # Convert '&' to '&amp;' only if it's not followed by an entity.
      string.gsub(/&(?!lt|gt|amp|quot|apos)/, '&amp;')
    end
  end
end
