require File.expand_path('./chat_builder', File.dirname(__FILE__))

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
