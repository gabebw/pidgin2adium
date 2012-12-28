# Usage:
# # determine format from passed-in file
# ChatBuilder.new('file.html') do |b|
#   b.first_line
#   b.message from: 'name1', from_alias: 'Gabe B-W',
#          time: '2010-01-30', text: 'blarg balrg'
#   b.message 'blerg' from: 'name2',
#     from_alias: 'another name', time: '2010-01-30'
#   b.away_message
#   b.status_message
# end


require File.expand_path('./file_builder', File.dirname(__FILE__))

module ChatBuilderMacros
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

class ChatBuilder
  DEFAULT_FROM = 'FROM_SN'

  def initialize(file)
    @file = file
    @first_line = nil
    @messages = []
  end

  def write(separator = "")
    @file.puts(first_line)
    @messages.each do |message|
      @file.puts(message + separator)
    end
    @file.close
  end
end

class TextChatBuilder < ChatBuilder
  def first_line(options = {})
    @first_line ||= begin
      to = options[:to] || 'TO'
      time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
      protocol = options[:protocol] || 'aim'
      from = options[:from] || DEFAULT_FROM
      "Conversation with #{to} at #{time} on #{from} (#{protocol})"
    end
  end

  def message(options = {})
    time = options[:time] || Time.now.strftime('%H:%M:%S')
    from_alias = options[:from_alias] || 'FROM'
    text = options[:text] || 'Hi there'
    message = "(#{time}) #{from_alias}: #{text}"
    @messages << message
  end
end

class HtmlChatBuilder < ChatBuilder
  def write
    super("<br/>")
  end

  def first_line(options = {})
    assert_keys(options, [:from, :to, :time, :protocol])

    @first_line ||= begin
      to = options[:to] || 'TO_SN'
      time = options[:time] || Time.now.strftime('%m/%d/%Y %I:%M:%S %p')
      protocol = options[:protocol] || 'aim'
      # Need to track this so we can set the message font color correctly.
      @from = options[:from] || DEFAULT_FROM
      %(<head><meta http-equiv="content-type" content="text/html; charset=UTF-8"><title>Conversation with #{to} at #{time} on #{@from} (#{protocol})</title></head><h3>Conversation with #{to} at #{time} on #{@from} (#{protocol})</h3>)
    end
  end

  def message(text = 'hello', options = {})
    assert_keys(options, [:from, :from_alias, :time, :font_color])

    from = options[:from] || DEFAULT_FROM
    from_alias = options[:from_alias] || 'FROM_ALIAS'
    time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    font_color = '#' + (options[:font_color] || font_color_for(from))
    message = %{<font color="#{font_color}"><font size="2">(#{time})</font> <b>#{from_alias}</b></font> #{text}}
    @messages << message
  end

  def status(text = 'Starting transfer of kitties.jpg from Gabe B-W', options = {})
    assert_keys(options, [:time])

    time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    @messages << %{<font size="2">(#{time})</font><b> #{text}</b>}
  end

  def auto_reply(text = 'ran out for a bit', options = {})
    assert_keys(options, [:time])

    from = options[:from] || DEFAULT_FROM
    from_alias = options[:from_alias] || 'FROM_ALIAS'
    time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    font_color = '#' + (options[:font_color] || font_color_for(from))

    message = %{<font color="#{font_color}"><font size="2">(#{time})</font> <b>#{from} &lt;AUTO-REPLY&gt;:</b></font> #{text}}
    @messages << message
  end

  private

  def assert_keys(options, possible_keys)
    extra_keys = options.keys - possible_keys
    unless extra_keys.empty?
      raise ArgumentError, "#{__method__} only takes the #{possible_keys}, got extra: #{extra_keys}"
    end
  end

  def font_color_for(from)
    if from == @from
      'A82F2F'
    else
      '16569E'
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
