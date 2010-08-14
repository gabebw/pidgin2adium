# The Message class's subclasses, each used for holding one line of a chat.

module Pidgin2Adium
  # A message saying e.g. "Blahblah has gone away."
  class StatusMessage < Message
    def initialize(sender, time, buddy_alias, status)
      super(sender, time, buddy_alias)
      @status = status
    end
    attr_accessor :status

    def to_s
      return sprintf('<status type="%s" sender="%s" time="%s" alias="%s"/>' << "\n",
                     @status, @sender, @time, @buddy_alias)
    end
  end
end
