require "spec_helper"

describe Pidgin2Adium::Runner do
  it "asks for aliases" do
    FileUtils.mkdir_p("HELLO")
    stdout = StringIO.new

    runner = Pidgin2Adium::Runner.new(path_to_file, stdout: stdout)
    runner.run

    expect(stdout.string).to eq "What are your aliases (comma-separated like Gabe,Gabe B-W)? > "
  end

  it "parses a Pidgin-formatted logfile and outputs it to the Adium log directory" do
    runner = Pidgin2Adium::Runner.new(path_to_file)
    runner.run
  end

  def path_to_file
    "FIXME"
  end
end
