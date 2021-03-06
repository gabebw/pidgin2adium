require "spec_helper"

describe Pidgin2Adium::AdiumChatFileCreator do
  unless on_travis_ci?
    include FakeFS::SpecHelpers
  end

  it "creates a file in the correct place" do
    chat = stub_chat

    chat_file_creator = Pidgin2Adium::AdiumChatFileCreator.new(path_to_file, %w(gabe))
    chat_file_creator.create

    expect(File.exist?(path_for(chat))).to be true
  end

  it "writes the correct prolog" do
    create_file

    expect(file_contents.first).to eq %(<?xml version="1.0" encoding="UTF-8" ?>\n)
  end

  it "writes the correct opening <chat> tag" do
    create_file

    second_line = file_contents[1]

    expect(second_line).to eq(
      %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="#{chat.my_screen_name}" service="AIM" adiumversion="1.5.9">\n)
    )
  end

  it "calls to_s on each message and puts it in the file" do
    create_file

    lines = file_contents[2, chat.messages.size]

    expect(lines.map(&:chomp)).to eq(chat.messages.map(&:to_s))
  end

  it "includes a closing </chat> tag" do
    create_file

    last_line = file_contents.last

    expect(last_line.chomp).to eq("</chat>")
  end

  def stub_chat(new_chat = chat)
    allow(Pipio).to receive(:parse).and_return(new_chat)
    new_chat
  end

  def chat
    time = Time.now
    messages = [:a, 1, 3]
    double(
      my_screen_name: "me",
      their_screen_name: "them",
      start_time: time,
      service: "aim",
      messages: messages,
      to_s: messages.map(&:to_s).join("\n")
    )
  end

  def file_contents
    File.readlines(path_for(chat))
  end

  def create_file
    chat = stub_chat
    chat_file_creator = Pidgin2Adium::AdiumChatFileCreator.new(path_to_file, %w(gabe))
    chat_file_creator.create
  end

  def path_for(chat)
    Pidgin2Adium::Runner::ADIUM_LOG_DIRECTORY.join(
      "AIM.#{chat.my_screen_name}",
      chat.their_screen_name,
      "#{chat.their_screen_name} (#{xmlschema_for(chat)}).chatlog",
      "#{chat.their_screen_name} (#{xmlschema_for(chat)}).xml"
    ).to_s
  end

  def xmlschema_for(chat)
    chat.start_time.xmlschema.sub(/:00$/, "00")
  end
end
