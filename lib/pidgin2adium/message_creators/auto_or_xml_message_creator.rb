module Pidgin2Adium
  class AutoOrXmlMessageCreator
    def initialize(text, time, my_screen_name, my_alias, is_auto_reply)
      @text = text
      @time = time
      @my_screen_name = my_screen_name
      @my_alias = my_alias
      @is_auto_reply = is_auto_reply
    end

    def create
      if auto_reply?
        AutoReplyMessage.new(@my_screen_name, @time, @my_alias, @text)
      else
        XMLMessage.new(@my_screen_name, @time, @my_alias, @text)
      end
    end

    private

    def auto_reply?
      !! @is_auto_reply
    end
  end
end
