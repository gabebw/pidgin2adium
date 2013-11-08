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
        my_alias = regex.match(@text)[1]
        my_screen_name = @alias_registry[my_alias]
        StatusMessage.new(my_screen_name, @time, my_alias, status)
      end
    end
  end
end
