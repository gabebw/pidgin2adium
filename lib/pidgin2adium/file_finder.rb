module Pidgin2Adium
  class FileFinder
    EXTENSIONS = %w(html htm txt)

    def initialize(directory)
      @directory = File.expand_path(directory)
    end

    def find
      Dir[glob]
    end

    private

    def glob
      File.join(@directory, "**/*.{#{comma_separated_extensions}}")
    end

    def comma_separated_extensions
      EXTENSIONS.join(",")
    end
  end
end
