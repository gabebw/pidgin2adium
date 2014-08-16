require "spec_helper"

describe "Parse a Pidgin log file" do
  before do
    FileUtils.rm_rf(tmp_directory)
  end

  it "outputs to the correct file" do
    runner = Pidgin2Adium::Runner.new(
      path_containing_pidgin_logs,
      ["Gabe B-W"],
      output_path
    )

    runner.run

    path = Dir["#{output_path}/**/*.xml"].first

    expect(path).to eq File.join(
      tmp_directory,
      "AIM.jiggerificbug",
      "them@gmail.com",
      "them@gmail.com (2014-03-16T23:55:43#{tz_offset}).chatlog",
      "them@gmail.com (2014-03-16T23:55:43#{tz_offset}).xml",
    )
  end

  def path_containing_pidgin_logs
    File.join(SPEC_ROOT, "fixtures", "input")
  end

  def output_path
    File.expand_path(File.join(SPEC_ROOT, "..", "tmp"))
  end

  def path_to_output_fixture
    File.join(SPEC_ROOT, "fixtures", "output.xml")
  end

  def tz_offset
    Time.now.strftime("%z").sub(":", "")
  end

  def tmp_directory
    File.join(
      File.dirname(SPEC_ROOT),
      "tmp"
    )
  end
end
