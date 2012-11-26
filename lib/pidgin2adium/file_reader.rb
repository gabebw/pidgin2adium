module Pidgin2Adium
  class FileReader
    def initialize(path_to_file, cleaner)
      @path_to_file = path_to_file
      @first_line = ''
      @other_lines = []
      @cleaner = cleaner
    end

    attr_reader :first_line, :other_lines

    def read
      if File.exist?(@path_to_file)
        open(@path_to_file) do |file|
          @first_line = file.readline.strip
          @other_lines = file.readlines.map(&:strip)
        end

        clean_other_lines
      end
    end

    private

    def clean_other_lines
      @other_lines.map! { |line| @cleaner.clean(line) }.reject!(&:empty?)
    end
  end
end
