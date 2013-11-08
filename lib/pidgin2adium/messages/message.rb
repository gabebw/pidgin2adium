module Pidgin2Adium
  # A holding object for each line of the chat. It is subclassed as
  # appropriate (eg AutoReplyMessage). Each subclass (but not Message
  # itself) has its own to_s which prints out its information in a format
  # appropriate for putting in an Adium log file.
  class Message
    include Comparable

    def initialize(my_screen_name, time, my_alias)
      @my_screen_name = my_screen_name
      @time = time
      @my_alias = my_alias
    end

    attr_reader :my_screen_name, :time, :my_alias

    # Compare this Message to +other_message+, based on their timestamps.
    def <=>(other_message)
      @time <=> other_message.time
    end

    private

    def adium_formatted_time
      @time.xmlschema
    end
  end
end
