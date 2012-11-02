describe Pidgin2Adium::Cleaners::HtmlCleaner, ".clean" do
  it "removes html, body, and font tags" do
    clean_text = 'clean'
    dirty_text = %{<html><body><font color="red">#{clean_text}</font></body></html>}
    clean(dirty_text).should == clean_text
  end

  it "removes those weird <FONT HSPACE> tags" do
    clean_text = 'clean'
    dirty_text = "&lt;/FONT HSPACE='2'>#{clean_text}"
    clean(dirty_text).should == clean_text
  end

  it 'removes \r' do
    clean_text = 'clean'
    dirty_text = [clean_text, clean_text, clean_text].join("\r")
    clean(dirty_text).should == clean_text * 3
  end

  it "removes empty lines" do
    clean_text = 'clean'
    dirty_text = "#{clean_text}\n\n"
    clean(dirty_text).should == clean_text
  end

  it "replaces newlines with <br/>" do
    clean_text = "<br/>clean"
    dirty_text = "\nclean"
    clean(dirty_text).should == clean_text
  end

  it "removes empty links" do
    clean_text = 'clean' * 2
    dirty_text = '<a href="awesomelink">   </a>clean' +
      "<a href='awesomelink'></a>clean"
    clean(dirty_text).should == clean_text
  end

  describe "with <span>s" do
    it "removes font-family" do
      clean_text = 'clean'
      dirty_text = %Q{<span style='font-family: Helvetica;'>#{clean_text}</span>}
      clean(dirty_text).should == clean_text
    end

    it "removes font-size" do
      clean_text = 'clean'
      dirty_text = %Q{<span style="font-size: 6;">#{clean_text}</span>}
      clean(dirty_text).should == clean_text
    end

    it "removes background" do
      clean_text = 'clean'
      dirty_text = %Q{<span style="background: #00afaf;">#{clean_text}</span>}
      clean(dirty_text).should == clean_text
    end

    it "removes color=#00000" do
      clean_text = 'clean'
      dirty_text = %Q{<span style="color: #000000;">#{clean_text}</span>}
      clean(dirty_text).should == clean_text
    end

    it "does not remove color that is not #00000" do
      dirty_text = %Q{<span style="color: #01ABcdef;">whatever</span>}
      clean(dirty_text).should == dirty_text
    end

    it "removes improperly-formatted colors" do
      clean_text = 'clean'
      dirty_text = %Q{<span style="color: #0;">#{clean_text}</span>}
      clean(dirty_text).should == clean_text
    end

    it "replaces <em> with italic font-style" do
      text = 'whatever'
      dirty_text = "<em>#{text}</em>"
      clean_text = %Q{<span style="font-style: italic;">#{text}</span>}
      clean(dirty_text).should == clean_text
    end

    it "does not modify clean text" do
      clean('clean').should == 'clean'
    end

    # This implicitly tests a lot of other things, but they've been tested
    # before this too.
    it "removes a trailing space after style declaration and replaces double quotes" do
      dirty_span_open = "<span style='color: #afaf00; font-size: 14pt; font-weight: bold; '>"
      # Replaced double quotes, removed space before ">"
      clean_span_open = '<span style="color: #afaf00;">'
      text = 'whatever'
      dirty_text = "#{dirty_span_open}#{text}</span>"
      clean_text = "#{clean_span_open}#{text}</span>"
      clean(dirty_text).should == clean_text
    end
  end

  def clean(line)
    Pidgin2Adium::Cleaners::HtmlCleaner.clean(line)
  end
end
