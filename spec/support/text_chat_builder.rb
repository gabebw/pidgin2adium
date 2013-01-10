require File.expand_path('./chat_builder', File.dirname(__FILE__))

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
