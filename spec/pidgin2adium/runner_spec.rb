require "spec_helper"

describe Pidgin2Adium::Runner do
  include FakeFS::SpecHelpers

  it "creates the Adium log directory if it does not exist" do
    run_runner(path_to_directory)

    expect(File.exist?(adium_log_directory)).to be true
  end

  it "parses a Pidgin-formatted logfile and outputs it to the Adium log directory" do
    file_finder = double(
      find: [path_to_file]
    )
    allow(Pidgin2Adium::FileFinder).to receive(:new).
      with(path_to_directory).and_return(file_finder)

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
end
