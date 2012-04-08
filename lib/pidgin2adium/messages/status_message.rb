module Pidgin2Adium
  # A message saying e.g. "Blahblah has gone away."
  class StatusMessage < Message
    def initialize(sender_screen_name, time, sender_alias, status)
      super(sender_screen_name, time, sender_alias)
      @status = status
    end

    attr_reader :status

    def to_s
      %(<status type="#{@status}" sender="#{@sender_screen_name}" time="#{@time}" alias="#{@sender_alias}"/>\n)
    end
  end
end
