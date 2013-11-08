module Pidgin2Adium
  # Pidgin does not have Events, but Adium does. Pidgin mostly uses system
  # messages to display what Adium calls events. These include sending a file,
  # starting a Direct IM connection, or an error in chat.
  class Event < XMLMessage
    # All of event_type libPurple.
    LIB_PURPLE = [
      # file transfer
      /Starting transfer of .+ from (.+)/,
      /^Offering to send .+ to (.+)$/,
      /(.+) is offering to send file/,
      /^Transfer of file .+ complete$/,
      /Error reading|writing|accessing .+: .+/,
      /You cancell?ed the transfer of/,
      /File transfer cancelled/,
      /(.+?) cancell?ed the transfer of/,
      /(.+?) cancelled the file transfer/,
      # Direct IM - actual (dis)connect events are their own types
      /^Attempting to connect to (.+) at .+ for Direct IM\./,
      /^Asking (.+) to connect to us at .+ for Direct IM\./,
      /^Attempting to connect via proxy server\.$/,
      /^Direct IM with (.+) failed/,
      # encryption
      /Received message encrypted with wrong key/,
      /^Requesting key\.\.\.$/,
      /^Outgoing message lost\.$/,
      /^Conflicting Key Received!$/,
      /^Error in decryption- asking for resend\.\.\.$/,
      /^Making new key pair\.\.\.$/,
      # sending errors
      /^Last outgoing message not received properly- resetting$/,
      /Resending\.\.\./,
      # connection errors
      /Lost connection with the remote user:.+/,
      # chats
      /^.+ entered the room\.$/,
      /^.+ left the room\.$/
    ]

    # Adium ignores SN/alias changes.
    IGNORE = [/^.+? is now known as .+?\.<br\/?>$/]

    # Each key maps to an event_type string. The keys will be matched against
    # a line of chat and the partner's alias will be in regex group 1, IF the
    # alias is matched.
    MAP = {
      # .+ is not an alias, it's a proxy server so no grouping
      /^Attempting to connect to .+\.$/ => 'direct-im-connect',
      # NB: pidgin doesn't track when Direct IM is disconnected, AFAIK
      /^Direct IM established$/ => 'directIMConnected',
      /Unable to send message/ => 'chat-error',
      /You missed .+ messages from (.+) because they were too large/ => 'chat-error',
      /User information not available/ => 'chat-error'
    }

    def initialize(my_screen_name, time, my_alias, body, event_type)
      super(my_screen_name, time, my_alias, body)
      @event_type = event_type
    end

    attr_reader :event_type

    def to_s
      %(<event type="#{@event_type}" sender="#{@my_screen_name}" time="#{adium_formatted_time}" alias="#{@my_alias}">#{@styled_body}</event>)
    end
  end
end
