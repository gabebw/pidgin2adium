module Pidgin2Adium
  # A message saying e.g. "Blahblah has gone away."
  class StatusMessage < Message
    MAP = {
      /(.+) logged in\.$/ => 'online',
      /(.+) logged out\.$/ => 'offline',
      /(.+) has signed on\.$/ => 'online',
      /(.+) has signed off\.$/ => 'offline',
      /(.+) has gone away\.$/ => 'away',
      /(.+) is no longer away\.$/ => 'available',
      /(.+) has become idle\.$/ => 'idle',
      /(.+) is no longer idle\.$/ => 'available'
    }

    def initialize(sender_screen_name, time, sender_alias, status)
      super(sender_screen_name, time, sender_alias)
      @status = status
    end

    attr_reader :status

    def to_s
      %(<status type="#{@status}" sender="#{@sender_screen_name}" time="#{adium_formatted_time}" alias="#{@sender_alias}"/>\n)
    end
  end
end
