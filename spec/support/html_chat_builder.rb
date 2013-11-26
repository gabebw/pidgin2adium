require File.expand_path('./chat_builder', File.dirname(__FILE__))

class HtmlChatBuilder < ChatBuilder
  def write
    super("<br/>")
  end

  def first_line(options = {})
    assert_keys(options, [:my_screen_name, :their_screen_name, :time, :protocol])

    @first_line ||= begin
      my_screen_name = options[:my_screen_name] || 'my_screen_name'
      time = options[:time] || Time.now.strftime('%m/%d/%Y %I:%M:%S %p')
      protocol = options[:protocol] || 'aim'
      # Need to track this so we can set the message font color correctly.
      @their_screen_name = options[:their_screen_name] || DEFAULT_THEIR_SCREEN_NAME
      %(<head><meta http-equiv="content-type" content="text/html; charset=UTF-8"><title>Conversation with #{@their_screen_name} at #{time} on #{my_screen_name} (#{protocol})</title></head><h3>Conversation with #{@their_screen_name} at #{time} on #{my_screen_name} (#{protocol})</h3>)
    end
  end

  def message(text = 'hello', options = {})
    assert_keys(options, [:sender_screen_name, :sender_alias, :time, :font_color, :format])

    sender_screen_name = options[:sender_screen_name] || DEFAULT_THEIR_SCREEN_NAME
    sender_alias = options[:sender_alias] || 'sender_alias'
    time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    font_color = '#' + (options[:font_color] || font_color_for(sender_screen_name))
    message_prefix = %{<font color="#{font_color}"><font size="2">(#{time})</font> <b>#{sender_alias}:</b></font> }
    body = case options[:format]
           when :span_tag_instead_of_font_tag
             %{<span style='color: #000000; font-size: x-small'>#{text}</span>}
           when :no_tag_around_body
             text
           else
             %{<font sml="AIM/ICQ">#{text}</font>}
           end
    @messages << (message_prefix + body)
  end

  def status(text = 'Starting transfer of kitties.jpg sender_screen_name Gabe B-W', options = {})
    assert_keys(options, [:time])

    time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    @messages << %{<font size="2">(#{time})</font><b> #{text}</b>}
  end

  def auto_reply(text = 'ran out for a bit', options = {})
    assert_keys(options, [:time])

    sender_screen_name = options[:sender_screen_name] || DEFAULT_SENDER_SCREEN_NAME
    sender_alias = options[:sender_alias] || 'sender_alias'
    time = options[:time] || Time.now.strftime('%Y-%m-%d %H:%M:%S')
    font_color = '#' + (options[:font_color] || font_color_for(sender_screen_name))

    message = %{<font color="#{font_color}"><font size="2">(#{time})</font> <b>#{sender_screen_name} &lt;AUTO-REPLY&gt;:</b></font> #{text}}
    @messages << message
  end

  private

  def assert_keys(options, possible_keys)
    extra_keys = options.keys - possible_keys
    unless extra_keys.empty?
      raise ArgumentError, "#{__method__} only takes #{possible_keys}, got extra: #{extra_keys}"
    end
  end

  def font_color_for(sender_screen_name)
    if sender_screen_name == @their_screen_name
      'A82F2F'
    else
      '16569E'
    end
  end
end
