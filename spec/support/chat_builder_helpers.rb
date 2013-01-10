require File.expand_path('./file_builder', File.dirname(__FILE__))

module ChatBuilderHelpers
  SPEC_DIR = File.dirname(File.dirname(__FILE__))
  TMP_DIRECTORY = File.join(SPEC_DIR, 'tmp')

  def create_chat_file(file_name = 'whatever.txt')
    file = FileBuilder.create_file(file_name)
    correct_builder_for(file).tap do |builder|
      yield builder if block_given?
      builder.write
    end
    file
  end

  def clean_up_generated_chat_files
    FileUtils.rm_rf(TMP_DIRECTORY)
  end

  private

  def correct_builder_for(file)
    if file.path =~ /\.html?$/
      HtmlChatBuilder.new(file)
    else
      TextChatBuilder.new(file)
    end
  end
end

RSpec.configure do |config|
  config.include ChatBuilderHelpers

  config.before do
    FileUtils.mkdir_p(ChatBuilderHelpers::TMP_DIRECTORY)
  end

  config.after do
    clean_up_generated_chat_files
  end
end
