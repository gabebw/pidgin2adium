module Pidgin2Adium
  class StatusMessageCreator
    def initialize(text, time, alias_registry)
      @text = text
      @time = time
      @alias_registry = alias_registry
    end

    def create
      regex, status = StatusMessage::MAP.detect { |rxp, stat| @text =~ rxp }

      if regex && status
        sender_alias = regex.match(@text)[1]
        sender_screen_name = @alias_registry[sender_alias]
        StatusMessage.new(sender_screen_name, @time, sender_alias, status)
      end
    end
  end
end
