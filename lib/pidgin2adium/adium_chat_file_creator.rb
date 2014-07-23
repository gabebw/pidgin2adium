module Pidgin2Adium
  class AdiumChatFileCreator
    ADIUM_LOG_DIRECTORY = Pathname.new(File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/'))

    def initialize(file_path)
      @file_path = file_path
    end

    def create
      create_containing_directory
      File.open(path, 'w') do |file|
        file.puts prolog
        file.puts opening_chat_tag
        file.puts chat.to_s
        file.puts closing_chat_tag
      end
    end

    private

    def create_containing_directory
      FileUtils.mkdir_p(File.dirname(path))
    end

    def path
      ADIUM_LOG_DIRECTORY.join(
        "#{chat.service}.#{chat.my_screen_name}",
        chat.their_screen_name,
        "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).chatlog",
        "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).xml"
      )
    end

    def prolog
      %(<?xml version="1.0" encoding="UTF-8" ?>)
    end

    def opening_chat_tag
      %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="#{chat.my_screen_name}" service="#{chat.service}" adiumversion="1.5.9">)
    end

    def closing_chat_tag
      "</chat>"
    end

    def chat
      @chat ||= Pipio::Chat.new(@file_path)
    end
  end
end
