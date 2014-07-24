require "spec_helper"

describe "Parse a pidgin log file" do
  include FakeFS::SpecHelpers

  it "outputs the correct data" do
    runner = Pidgin2Adium::Runner.new("./in-logs", ["gabe"])

    runner.run

    fail "Needs: pidgin file, expected adium output"
  end
end
