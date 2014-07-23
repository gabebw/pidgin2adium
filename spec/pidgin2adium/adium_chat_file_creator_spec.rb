require "spec_helper"

describe Pidgin2Adium::AdiumChatFileCreator do
  it "parses a Pidgin-formatted logfile and outputs it to the Adium log directory" do
    time = Time.now.xmlschema

    chat = double(
      my_screen_name: "me",
      their_screen_name: "them",
      start_time_xmlschema: time,
      service: "aim",
    )
    allow(Pipio::Chat).to receive(:new).and_return(chat)

    run_runner(path_to_directory)

    path = "#{adium_log_directory}/aim.me/them/them (#{time}).chatlog/them (#{time}).xml"

    expect(File.exist?(path)).to be true
  end
end
