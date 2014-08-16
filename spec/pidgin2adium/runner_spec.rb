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

    path = output_path(chat)

    expect(File.exist?(path)).to be true
  end

  it "puts the correct data in the Adium file" do
    chat = stubbed_chat(lines: %w(one two three))

    path = output_path(chat)
    content = File.read(path)
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

  def output_path(chat)
    File.join(
      adium_log_directory,
      "#{chat.service}.#{chat.my_screen_name}",
      chat.their_screen_name,
      "#{chat.their_screen_name} (#{chat.start_time.xmlschema}).chatlog",
      "#{chat.their_screen_name} (#{chat.start_time.xmlschema}).xml"
    )
  end

  def stubbed_chat(options = {})
    time = Time.now
    chat = double({
      lines: %w(one two three),
      my_screen_name: "me",
      their_screen_name: "them",
      start_time: time,
      service: "aim",
    }.merge(options))
    allow(Pipio::Chat).to receive(:new).and_return(chat)
    chat
  end
end
