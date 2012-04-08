module Pidgin2Adium
  class Metadata
    def initialize(metadata_hash)
      @sender_screen_name = normalize_screen_name(metadata_hash[:sender_screen_name])
      @receiver_screen_name = metadata_hash[:receiver_screen_name]
      @start_time = metadata_hash[:start_time]
    end

    attr_reader :sender_screen_name, :receiver_screen_name

    def valid?
      [@receiver_screen_name, @sender_screen_name, @start_time].all?
    end

    def start_year
      @start_time.year
    end

    def start_month
      @start_time.mon
    end

    def start_mday
      @start_time.mday
    end

    private

    def normalize_screen_name(screen_name)
      screen_name && screen_name.downcase.gsub(' ', '')
    end
  end
end
