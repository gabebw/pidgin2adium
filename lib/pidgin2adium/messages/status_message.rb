module Pidgin2Adium
  # A message saying e.g. "Blahblah has gone away."
  class StatusMessage < Message
    def initialize(sender, time, buddy_alias, status)
      super(sender, time, buddy_alias)
      @status = status
    end

    attr_reader :status

    def to_s
      %(<status type="#{@status}" sender="#{@sender}" time="#{@time}" alias="#{@buddy_alias}"/>\n)
    end
  end
end
