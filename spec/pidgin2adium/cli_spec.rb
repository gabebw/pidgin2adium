require "spec_helper"

describe Pidgin2Adium::Cli do
  context "#parse" do
    it "passes in_directory and aliases to a Runner" do
      runner = double("runner", run: nil)
      allow(Pidgin2Adium::Runner).to receive(:new).and_return(runner)

      argv = %w(--in home --aliases gabe,me)
      cli = Pidgin2Adium::Cli.new(argv)
      cli.parse_and_run

      expect(Pidgin2Adium::Runner).to have_received(:new).with(
        "home", %w(gabe me)
      )
      expect(runner).to have_received(:run)
    end

    it "prints to stderr if --in is missing" do
      stderr = StringIO.new

      cli = Pidgin2Adium::Cli.new(%w(-a hello), stderr: stderr)

      rescuing_from_exit { cli.parse_and_run }

      expect(stderr.string).to include "Please provide"
    end

    it "prints to stderr if --aliases is missing" do
      stderr = StringIO.new

      cli = Pidgin2Adium::Cli.new(%w(--in home), stderr: stderr)

      rescuing_from_exit { cli.parse_and_run }

      expect(stderr.string).to include "Please provide"
    end

    it "prints its version" do
      stdout = StringIO.new

      cli = Pidgin2Adium::Cli.new(%w(-v), stdout: stdout)

      rescuing_from_exit { cli.parse_and_run }

      expect(stdout.string).to eq "Pidgin2Adium, version #{Pidgin2Adium::VERSION}\n"
    end

    def rescuing_from_exit
      begin
        yield
      rescue SystemExit
      end
    end
  end
end
