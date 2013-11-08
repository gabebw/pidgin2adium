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

    def initialize(my_screen_name, time, my_alias, status)
      super(my_screen_name, time, my_alias)
      @status = status
    end

    attr_reader :status

    def to_s
      %(<status type="#{@status}" sender="#{@my_screen_name}" time="#{adium_formatted_time}" alias="#{@my_alias}"/>\n)
    end
  end
end
