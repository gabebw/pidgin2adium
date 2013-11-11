require File.expand_path('./chat_builder', File.dirname(__FILE__))

class TextChatBuilder < ChatBuilder
  def first_line(options = {})
    @first_line ||= begin
      my_screen_name = options[:my_screen_name] || 'my_screen_name'
      time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
      protocol = options[:protocol] || 'aim'
      their_screen_name = options[:their_screen_name] || DEFAULT_THEIR_SCREEN_NAME
      "Conversation with #{their_screen_name} at #{time} on #{my_screen_name} (#{protocol})"
    end
  end

  def message(options = {})
    time = options[:time] || Time.now.strftime('%H:%M:%S')
    from_alias = options[:from_alias] || 'Gabe'
    text = options[:text] || 'Hi there'
    message = "(#{time}) #{from_alias}: #{text}"
    @messages << message
  end
end
