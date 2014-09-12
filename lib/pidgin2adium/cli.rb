module Pidgin2Adium
  class Cli
    def initialize(options, stdout=STDOUT, stderr=STDERR)
      @options = options
      @stdout = stdout
      @stderr = stderr
    end

    def run
      if @options[:in_directory] && @options[:aliases]
        runner = Runner.new(@options[:in_directory], @options[:aliases])
        runner.run
      else
        @stderr.puts "Please provide -i/--in argument and -a/--aliases. Run with --help for more information"
        exit 1
      end
    end
  end
end
