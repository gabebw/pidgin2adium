module Pidgin2Adium
  class AdiumChatFileCreator
    def initialize(file_path)
      @file_path = file_path
    end

    def create_file
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end

    def write_file
      File.open(path, 'w') do |file|
        file.puts prolog
        file.puts chat_tag
      end
    end

    private

    def path
      Pidgin2Adium::ADIUM_LOG_DIRECTORY.join(
        "#{chat.service}.#{chat.my_screen_name}",
        chat.their_screen_name,
        "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).chatlog",
        "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).xml"
      )
    end

    def prolog
      %(<?xml version="1.0" encoding="UTF-8" ?>)
    end

    def chat_tag
      %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="#{chat.my_screen_name}" service="#{chat.service}" adiumversion="1.5.9">)
    end

    def chat
      @chat ||= Pipio::Chat.new(@file_path)
    end
  end
end
