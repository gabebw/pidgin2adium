module Pidgin2Adium
  class ArgumentParser
    def initialize(argv)
      @argv = argv
      @options = {}
    end

    def parse
      parser.parse!(@argv)
      @options
    end

    private

    def parser
      OptionParser.new do |parser|
        parser.banner = "Usage: #{File.basename($0)} -i PIDGIN_LOG_DIR"

        parser.on('-i', '--in IN_DIR', 'Directory where pidgin logs are stored') do |in_directory|
          @options[:in_directory] = in_directory
        end

        parser.on('-o', '--out OUT_DIR', 'Directory where converted logs will be output to') do |out_directory|
          @options[:out_directory] = out_directory
        end

        parser.on('-a', '--aliases "gabebw,Gabe B-W"', "Your aliases from Pidgin") do |aliases|
          @options[:aliases] = aliases.split(",")
        end

        parser.on("-v", "--version", "Show version information") do
          $stdout.puts "Pidgin2Adium, version #{Pidgin2Adium::VERSION}"
          exit
        end

        parser.on_tail("-h", "--help", "Show this message") do
          $stdout.puts parser
          exit
        end
      end
    end
  end
end

