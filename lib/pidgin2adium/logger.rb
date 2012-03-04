module Pidgin2Adium
  class Logger
    def initialize(output = $STDOUT)
      @messages = []
      @output = output
    end

    def log(message)
      @messages << message
    end

    def oops(message)
      @messages << "Oops: #{message}"
    end

    def error(message)
      @messages << "Error: #{message}"
    end

    def flush
      @messages.each do |message|
        @output.puts message
      end
    end
  end
end
