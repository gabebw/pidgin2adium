require "spec_helper"

describe "Parse a Pidgin log file" do
  before do
    FileUtils.rm_rf(tmp_directory)
  end

  context "with good input" do
    before do
      $stdout = StringIO.new
    end

    it "outputs to the correct file" do
      runner = Pidgin2Adium::Runner.new(
        path_containing_good_pidgin_logs,
        ["Gabe B-W"],
        output_path
      )

      runner.run

      path = Dir["#{output_path}/**/*.xml"].first

      timestamp = Time.parse("2014-03-16 11:55:43 AM #{Time.now.zone}").utc.xmlschema
      # STDOUT.puts timestamp
      # STDOUT.puts timestamp.utc
      # STDOUT.puts timestamp.utc.xmlschema

      expect(path).to eq File.join(
        tmp_directory,
        "AIM.jiggerificbug",
        "them@gmail.com",
        "them@gmail.com (#{timestamp}).chatlog",
        "them@gmail.com (#{timestamp}).xml",
      )
    end

    it "does not print an error message" do
      $stderr = StringIO.new

      runner = Pidgin2Adium::Runner.new(
        path_containing_good_pidgin_logs,
        ["Gabe B-W"],
        output_path
      )

      runner.run

      expect($stderr.string).to eq ""
    end

    it "prints a dot to stdout" do
      $stdout = StringIO.new

      runner = Pidgin2Adium::Runner.new(
        path_containing_good_pidgin_logs,
        ["Gabe B-W"],
        output_path
      )

      runner.run

      expect($stdout.string).to eq "."
    end

  end

  it "prints an error message if the chat is unparseable" do
    $stderr = StringIO.new

    runner = Pidgin2Adium::Runner.new(
      path_containing_bad_pidgin_logs,
      ["Gabe B-W"],
      output_path
    )

    runner.run

    expect($stderr.string).to match /Could not parse.*bad_input\/bad.html/
  end


  def path_containing_good_pidgin_logs
    File.join(SPEC_ROOT, "fixtures", "input")
  end

  def path_containing_bad_pidgin_logs
    File.join(SPEC_ROOT, "fixtures", "bad_input")
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
