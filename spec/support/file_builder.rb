require 'fileutils'

module FileBuilder
  SPEC_DIR = File.dirname(File.dirname(__FILE__))
  OUTPUT_PATH = File.join(SPEC_DIR, 'built-files')

  def self.create_file(path, &block)
    path_to_created_file = File.join(OUTPUT_PATH, path)
    FileUtils.mkdir_p(File.dirname(path_to_created_file))
    open(path_to_created_file, 'w', &block)
  end

  def self.remove_created_files
    FileUtils.rm_rf(OUTPUT_PATH)
  end
end

RSpec.configure do |config|
  config.after do
    FileBuilder.remove_created_files
  end
end
