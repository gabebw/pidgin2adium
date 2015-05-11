module Pidgin2Adium
  class AdiumChatFileCreator
    def initialize(file_path, aliases, output_directory = Runner::ADIUM_LOG_DIRECTORY)
      @file_path = file_path
      @aliases = aliases
      @output_directory = Pathname.new(output_directory.to_s)
    end

    def create
      if chat
        create_containing_directory
        File.open(path, 'w') do |file|
          file.puts xml_prolog
          file.puts opening_chat_tag
          file.puts chat.to_s
          file.puts closing_chat_tag
        end
        true
      else
        false
      end
    end

    private

    def create_containing_directory
      FileUtils.mkdir_p(File.dirname(path))
    end

    def path
      @output_directory.join(
        "#{normalized_service}.#{chat.my_screen_name}",
        chat.their_screen_name,
        "#{chat.their_screen_name} (#{formatted_start_time}).chatlog",
        "#{chat.their_screen_name} (#{formatted_start_time}).xml"
      )
    end

    def xml_prolog
      %(<?xml version="1.0" encoding="UTF-8" ?>)
    end

    def opening_chat_tag
      %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="#{chat.my_screen_name}" service="#{normalized_service}" adiumversion="1.5.9">)
    end

    def closing_chat_tag
      "</chat>"
    end

    def formatted_start_time
      # FIXME: turn `xx:xx:xxZ` into `xx.xx.xxZ`
      STDOUT.puts "chat: #{chat.start_time}"
      chat.start_time.xmlschema.sub(/:00$/, "00")
    end

    def normalized_service
      if chat.service == "aim"
        "AIM"
      else
        chat.service
      end
    end

    def chat
      @chat ||= Pipio.parse(@file_path, @aliases)
    end
  end
end
