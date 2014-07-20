require "spec_helper"

describe Pidgin2Adium::Runner do
  include FakeFS::SpecHelpers

  it "asks for aliases" do
    stdout = StringIO.new

    runner = Pidgin2Adium::Runner.new(path_to_file, stdout: stdout)
    runner.run

    expect(stdout.string).to eq "What are your aliases (comma-separated like Gabe,Gabe B-W)? > "
  end

  it "creates the Adium log directory if it does not exist" do
    runner = Pidgin2Adium::Runner.new(path_to_file)
    runner.run

    expect(File.exist?(adium_log_dir)).to be true
  end


  it "parses a Pidgin-formatted logfile and outputs it to the Adium log directory" do
    runner = Pidgin2Adium::Runner.new(path_to_file)
    runner.run

  end

  def path_to_file
    "FIXME"
  end

  def adium_log_dir
    File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/')
  end
end
