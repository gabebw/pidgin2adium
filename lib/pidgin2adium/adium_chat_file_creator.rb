module Pidgin2Adium
  class AdiumChatFileCreator
    def initialize(file_path)
      @file_path = file_path
    end

    def create
      path = Pidgin2Adium::ADIUM_LOG_DIRECTORY.join(
        "#{chat.service}.#{chat.my_screen_name}",
        chat.their_screen_name,
        "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).chatlog",
        "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).xml"
      )
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end

    private

    def chat
      @chat ||= Pipio::Chat.new(@file_path)
    end
  end
end
