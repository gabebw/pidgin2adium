module Pidgin2Adium
  class Logger
    def initialize(output = $STDOUT)
      @warnings = []
      @errors = []
      @output = output
    end

    def log(message)
      @output.puts(message)
    end

    def warn(message)
      @warnings << "Warning: #{message}"
    end

    def error(message)
      @errors << "Error: #{message}"
    end

    def flush_warnings_and_errors
      flush_warnings
      flush_errors
    end

    private

    def flush_warnings
      if @warnings.size > 0
        @output.puts "Minor error messages:"
        @warnings.each do |warning|
          @output.puts(warning)
        end
      end
    end

    def flush_errors
      if @errors.size > 0
        @output.puts "Major error messages:"
        @errors.each do |error|
          @output.puts(error)
        end
      end
    end
  end
end
