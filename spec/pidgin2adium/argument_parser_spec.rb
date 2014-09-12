require "spec_helper"

describe Pidgin2Adium::ArgumentParser do
  context "#parse" do
    %w(-i --in).each do |format|
      it "can parse out in_directory as #{format}" do
        runner = double("runner", run: nil)
        allow(Pidgin2Adium::Runner).to receive(:new).and_return(runner)

        argv = [format, "home"]
        parser = Pidgin2Adium::ArgumentParser.new(argv)
        options = parser.parse

        expect(options[:in_directory]).to eq "home"
      end
    end

    %w(--aliases -a).each do |format|
      it "can parse out aliases from #{format}" do
        argv = [format, "gabe,me"]

        parser = Pidgin2Adium::ArgumentParser.new(argv)
        options = parser.parse

        expect(options[:aliases]).to eq %w(gabe me)
      end
    end

    %w(-v --version).each do |format|
      it "prints out its version when passed #{format}" do
        $stdout = StringIO.new

        parser = Pidgin2Adium::ArgumentParser.new([format])

        rescuing_from_exit { parser.parse }

        expect($stdout.string).to eq "Pidgin2Adium, version #{Pidgin2Adium::VERSION}\n"
      end
    end

    def rescuing_from_exit
      begin
        yield
      rescue SystemExit
      end
    end
  end
end
