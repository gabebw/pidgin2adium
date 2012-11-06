=begin
For building chats - like factory_girl, but using the builder pattern.
Ideally it'll work something like this:

# determine format from passed-in file
ChatBuilder.new('file.html') do |b|
  b.first_line
  b.message from: "name1", from_alias: "Gabe B-W",
         time: '2010-01-30', text: "blarg balrg"
  b.message from: "name2", from_alias: "another name",
         text: "balrg blarg", time: '2010-01-30'
  b.away_message
  b.status_message
end
=end

module ChatBuilderMacros
  SPEC_DIR = File.dirname(File.dirname(__FILE__))
  TMP_DIRECTORY = File.join(SPEC_DIR, 'tmp')

  def create_chat_file(file_name = 'whatever.txt')
    path = File.join(TMP_DIRECTORY, file_name)
    correct_builder_for(path).tap do |builder|
      yield builder if block_given?
      builder.write
    end
    path
  end

  def clean_up_generated_chat_files
    FileUtils.rm_rf(TMP_DIRECTORY)
  end

  private

  def correct_builder_for(path)
    if path =~ /\.html?$/
      HtmlChatBuilder.new(path)
    else
      TextChatBuilder.new(path)
    end
  end
end

class ChatBuilder
  def initialize(path)
    @path = path
    @file = File.new(path, 'w')
    @first_line = nil
    @messages = []
  end

  def write
    @file.puts(first_line)
    @messages.each do |message|
      @file.puts(message)
    end
    @file.close
  end
end

class TextChatBuilder < ChatBuilder
  def first_line(options = {})
    @first_line ||= begin
      to = options[:to] || "TO"
      time = options[:time] || Time.now.strftime("%Y-%m-%d %H:%M:%S")
      protocol = options[:protocol] || "aim"
      from = options[:from] || "FROM_SN"
      "Conversation with #{to} at #{time} on #{from} (#{protocol})"
    end
  end

  def message(options = {})
    time = options[:time] || Time.now.strftime("%H:%M:%S")
    from_alias = options[:from_alias] || "FROM"
    text = options[:text] || "What's up?"
    message = "(#{time}) #{from_alias}: #{text}"
    @messages << message
  end
end

class HtmlChatBuilder < ChatBuilder
  DEFAULT_FROM = "FROM_SN"

  def first_line(options = {})
    @first_line ||= begin
      to = options[:to] || "TO_SN"
      time = options[:time] || Time.now.strftime("%m/%d/%Y %I:%M:%S %p")
      protocol = options[:protocol] || "aim"
      # Need to track this so we can set the message font color correctly.
      @from = options[:from] || DEFAULT_FROM
      %(<head><meta http-equiv="content-type" content="text/html; charset=UTF-8"><title>Conversation with #{to} at #{time} on #{@from} (#{protocol})</title></head><h3>Conversation with #{to} at #{time} on #{@from} (#{protocol})</h3>)
    end
  end

  def message(options = {})
    from = options[:from] || DEFAULT_FROM
    from_alias = options[:from_alias] || "FROM_ALIAS"
    time = options[:time] || Time.now.strftime("%Y-%m-%d %H:%M:%D")
    text = options[:text] || "What's up?"
    font_color = "#" + (options[:font_color] || font_color_for(from))
    message = %{<font color="#{font_color}"><font size="2">(#{time})</font> <b>#{from_alias}</b></font> #{text}<br/>}
    @messages << message
  end

  private

  def font_color_for(from)
    if from == @from
      "A82F2F"
    else
      "16569E"
    end
  end
end

RSpec.configure do |config|
  config.include ChatBuilderMacros

  config.before do
    FileUtils.mkdir_p(ChatBuilderMacros::TMP_DIRECTORY)
  end

  config.after do
    clean_up_generated_chat_files
  end
end
