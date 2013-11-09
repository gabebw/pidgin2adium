module Pidgin2Adium
  class AutoOrXmlMessageCreator
    def initialize(text, time, sender_screen_name, sender_alias, is_auto_reply)
      @text = text
      @time = time
      @sender_screen_name = sender_screen_name
      @sender_alias = sender_alias
      @is_auto_reply = is_auto_reply
    end

    def create
      if auto_reply?
        AutoReplyMessage.new(@sender_screen_name, @time, @sender_alias, @text)
      else
        XMLMessage.new(@sender_screen_name, @time, @sender_alias, @text)
      end
    end

    private

    def auto_reply?
      !! @is_auto_reply
    end
  end
end
