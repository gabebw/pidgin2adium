require "spec_helper"

describe Pidgin2Adium::Cli do
  context "#run" do
    it "passes in_directory and aliases to a Runner" do
      runner = double("runner", run: nil)
      allow(Pidgin2Adium::Runner).to receive(:new).and_return(runner)

      options = {
        in_directory: "home",
        aliases: %w(gabe me)
      }
      cli = Pidgin2Adium::Cli.new(options)
      cli.run

      expect(Pidgin2Adium::Runner).to have_received(:new).with(
        "home", %w(gabe me), nil
      )
      expect(runner).to have_received(:run)
    end

    it "passes out_directory to runner" do
      runner = double("runner", run: nil)
      allow(Pidgin2Adium::Runner).to receive(:new).and_return(runner)

      options = {
        in_directory: "home",
        out_directory: "out",
        aliases: %w(gabe me)
      }
      cli = Pidgin2Adium::Cli.new(options)
      cli.run

      expect(Pidgin2Adium::Runner).to have_received(:new).with(
        "home", %w(gabe me), "out"
      )
      expect(runner).to have_received(:run)
    end

    it "prints to stderr if --in is missing" do
      stderr = StringIO.new

      options = { aliases: %w(hello) }
      cli = Pidgin2Adium::Cli.new(options, STDOUT, stderr)

      rescuing_from_exit { cli.run }

      expect(stderr.string).to include "Please provide"
    end

    it "prints to stderr if --aliases is missing" do
      stderr = StringIO.new

      options = { in_directory: "home" }
      cli = Pidgin2Adium::Cli.new(options, STDOUT, stderr)

      rescuing_from_exit { cli.run }

      expect(stderr.string).to include "Please provide"
    end

    def rescuing_from_exit
      begin
        yield
      rescue SystemExit
      end
    end
  end
end
