module Pidgin2Adium
  # A holding object for each line of the chat. It is subclassed as
  # appropriate (eg AutoReplyMessage). Each subclass (but not Message
  # itself) has its own to_s which prints out its information in a format
  # appropriate for putting in an Adium log file.
  class Message
    include Comparable

    def initialize(sender, adium_formatted_time, buddy_alias)
      # The sender's screen name
      @sender = sender
      @time = adium_formatted_time
      @time_object = Time.parse(@time)
      # The receiver's alias (NOT screen name)
      @buddy_alias = buddy_alias
    end

    attr_reader :sender, :time, :buddy_alias

    # Compare this Message to +other_message+, based on their timestamps.
    def <=>(other_message)
      @time_object - other_message.time_object
    end

    protected

    def time_object
      @time_object
    end
  end
end
