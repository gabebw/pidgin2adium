require "spec_helper"

describe Pidgin2Adium::Runner do
  include FakeFS::SpecHelpers

  it "passes every found file to the file creator" do
    file_finder = double(
      find: [path_to_file]
    )
    creator = double(create: nil)
    allow(Pidgin2Adium::FileFinder).to receive(:new).
      with(path_to_directory).and_return(file_finder)

    chat = stubbed_chat

    run_runner(path_to_directory)

    path = "#{adium_log_directory}/aim.me/them/them (#{chat.start_time_xmlschema}).chatlog/them (#{chat.start_time_xmlschema}).xml"

    expect(File.exist?(path)).to be true
  end

  def path_to_file
    File.join(path_to_directory, "gabebw", "in.html")
  end

  def path_to_directory
    File.expand_path("./in-logs/")
  end

  def adium_log_directory
    File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/')
  end

  def run_runner(path)
    runner = Pidgin2Adium::Runner.new(path)
    runner.run
  end

  def stubbed_chat
    timestamp = Time.now.xmlschema
    chat = double(
      my_screen_name: "me",
      their_screen_name: "them",
      start_time_xmlschema: timestamp,
      service: "aim",
    )
    allow(Pipio::Chat).to receive(:new).and_return(chat)
    chat
  end
end
