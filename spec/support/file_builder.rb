require 'fileutils'

module FileBuilderHelpers
  SPEC_DIR = File.dirname(File.dirname(__FILE__))
  OUTPUT_PATH = File.join(SPEC_DIR, 'built-files')

  def create_file(path, &block)
    path_to_created_file = File.join(OUTPUT_PATH, path)
    FileUtils.mkdir_p(File.dirname(path_to_created_file))
    open(path_to_created_file, 'w', &block)
    path_to_created_file
  end

  def remove_created_files
    FileUtils.rm_rf(OUTPUT_PATH)
  end
end

RSpec.configure do |config|
  config.include FileBuilderHelpers

  config.after do
    remove_created_files
  end
end
