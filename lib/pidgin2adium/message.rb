module Pidgin2Adium
  class Message
    def initialize(properties)
      @time = properties[:time]
      @sender_alias = properties[:sender_alias]
      @sender_screen_name = properties[:sender_screen_name]
      @body = properties[:body]
    end

    attr_reader :time, :sender_alias, :sender_screen_name, :body
  end
end
