module Pidgin2Adium
  # Map aliases ("Gabe B-W") to screen names ("cool_dragon_88").
  class AliasRegistry
    def initialize(default)
      @items = Hash.new(normalize(default))
    end

    def []=(alias_name, screen_name)
      @items[alias_name] = normalize(screen_name)
    end

    def [](alias_name)
      @items[without_action(alias_name)]
    end

    private

    def normalize(screen_name)
      screen_name.gsub(' ', '').downcase
    end

    def without_action(alias_name)
      alias_name.sub(/^\*{3}/, '')
    end
  end
end
