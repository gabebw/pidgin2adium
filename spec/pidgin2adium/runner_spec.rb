require "spec_helper"

describe Pidgin2Adium::Runner do
  include FakeFS::SpecHelpers

  it "creates the Adium log directory if it does not exist" do
    run_runner(path_to_directory)

    expect(File.exist?(adium_log_directory)).to be true
  end

  it "passes every found file to the file creator" do
    file_finder = double(
      find: [path_to_file]
    )
    creator = double(create: nil)
    allow(Pidgin2Adium::FileFinder).to receive(:new).
      with(path_to_directory).and_return(file_finder)
    allow(Pidgin2Adium::AdiumChatFileCreator).to receive(:new).
      and_return(creator)

    run_runner(path_to_directory)

    expect(Pidgin2Adium::AdiumChatFileCreator).to have_received(:new).with(path_to_file)
    expect(creator).to have_received(:create)
  end

  def adium_log_directory
    File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/')
  end

  def run_runner(path)
    runner = Pidgin2Adium::Runner.new(path)
    runner.run
  end
end
