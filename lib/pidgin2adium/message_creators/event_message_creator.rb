module Pidgin2Adium
  class EventMessageCreator
    def initialize(text, time, my_alias, my_screen_name, alias_registry)
      @text = text
      @time = time
      @my_alias = my_alias
      @my_screen_name = my_screen_name
      @alias_registry = alias_registry
    end

    def create
      create_lib_purple_event_message ||
        create_non_lib_purple_event_message
    end

    private

    def create_lib_purple_event_message
      regex = Event::LIB_PURPLE.detect { |rxp| @text =~ rxp }
      if regex
        event_type = 'libpurpleEvent'
        create_event_message_from(regex, event_type)
      end
    end

    def create_non_lib_purple_event_message
      regex, event_type = Event::MAP.detect { |rxp,ev_type| @text =~ rxp }
      if regex && event_type
        create_event_message_from(regex, event_type)
      end
    end

    def create_event_message_from(regex, event_type)
      regex_matches = regex.match(@text)
      if regex_matches.size == 1
        # No alias - this means it's the user
        my_alias = @my_alias
        my_screen_name = @my_screen_name
      else
        my_alias = regex_matches[1]
        my_screen_name = @alias_registry[my_alias]
      end

      Event.new(my_screen_name, @time, my_alias, @text, event_type)
    end
  end
end
