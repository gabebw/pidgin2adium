module Pidgin2Adium
  class Cli
    def initialize(args, stdout=STDOUT, stderr=STDERR)
      @arguments = args
      @stdout = stdout
      @stderr = stderr
      @options = {}
    end

    def parse_and_run
      parser.parse!(@arguments)

      if @options[:in_directory] && @options[:aliases]
        runner = Runner.new(@options[:in_directory], @options[:aliases])
        runner.run
      else
        @stderr.puts "Please provide -i/--in argument and -a/--aliases. Run with --help for more information"
        exit 1
      end
    end

    private

    def parser
      @parser ||= OptionParser.new do |parser|
        parser.banner = "Usage: #{File.basename($0)} -i PIDGIN_LOG_DIR"

        parser.on('-i', '--in IN_DIR', 'Directory where pidgin logs are stored') do |in_directory|
          @options[:in_directory] = in_directory
        end

        parser.on('-a', '--aliases "gabebw,Gabe B-W"', "Your aliases from Pidgin") do |aliases|
          @options[:aliases] = aliases.split(",")
        end

        parser.on("-v", "--version", "Show version information") do
          @stdout.puts "Pidgin2Adium, version #{Pidgin2Adium::VERSION}"
          exit
        end

        parser.on_tail("-h", "--help", "Show this message") do
          @stdout.puts parser
          exit
        end
      end
    end
  end
end
