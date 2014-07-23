require "spec_helper"

describe Pidgin2Adium::AdiumChatFileCreator do
  it "creates a file in the correct place" do
    chat = stub_chat

    chat_file_creator = Pidgin2Adium::AdiumChatFileCreator.new(path_to_file)
    chat_file_creator.create_file

    expect(File.exist?(path_for(chat))).to be true
  end

  it "writes the correct prolog" do
    write_file

    expect(file_contents.first).to eq %(<?xml version="1.0" encoding="UTF-8" ?>\n)
  end

  it "writes the correct opening <chat> tag" do
    write_file

    second_line = file_contents[1]

    expect(second_line).to eq(
      %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="#{chat.my_screen_name}" service="#{chat.service}" adiumversion="1.5.9">\n)
    )
  end

  def stub_chat(new_chat = chat)
    allow(Pipio::Chat).to receive(:new).and_return(new_chat)
    new_chat
  end

  def chat(options = {})
    timestamp = Time.now.xmlschema
    double({
      my_screen_name: "me",
      their_screen_name: "them",
      start_time_xmlschema: timestamp,
      service: "aim",
      lines: %w(a b c)
    }.merge(options))
  end

  def file_contents
    File.readlines(path_for(chat))
  end

  def write_file
    chat = stub_chat
    chat_file_creator = Pidgin2Adium::AdiumChatFileCreator.new(path_to_file)
    chat_file_creator.create_file
    chat_file_creator.write_file
  end

  def path_for(chat)
    Pidgin2Adium::ADIUM_LOG_DIRECTORY.join(
      "#{chat.service}.#{chat.my_screen_name}",
      chat.their_screen_name,
      "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).chatlog",
      "#{chat.their_screen_name} (#{chat.start_time_xmlschema}).xml"
    )
  end
end
