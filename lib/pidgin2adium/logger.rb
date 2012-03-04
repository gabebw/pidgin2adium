module Pidgin2Adium
  class Logger
    def initialize(output = $STDOUT)
      @log_messages = []
      @oops_messages = []
      @error_messages = []
      @output = output
    end

    def log(message)
      @log_messages << message
    end

    def oops(message)
      @oops_messages << "Oops: #{message}"
    end

    def error(message)
      @error_messages << "Error: #{message}"
    end

    def flush
      flush_log_messages
      flush_oops_messages
      flush_error_messages
    end

    private

    def flush_log_messages
      @log_messages.each do |message|
        @output.puts message
      end
    end

    def flush_oops_messages
      if @oops_messages.size > 0
        @output.puts "Minor error messages:"
        @oops_messages.each do |message|
          @output.puts message
        end
      end
    end

    def flush_error_messages
      if @error_messages.size > 0
        @output.puts "Major error messages:"
        @error_messages.each do |message|
          @output.puts message
        end
      end
    end
  end
end
