require 'spec_helper'

describe "TextLogParser" do
  before(:each) do
    @time = '(04:20:06)'
  end
  it "should cleanup text correctly" do
    dirty_text = %Q{\r\n#{@time}&<b>Hello!</b> "Hi!" 'Oh no'\n}
    # "\n" not removed if it ends a line or is followed by
    # a timestamp
    clean_text = %Q{\n#{@time}&amp;&lt;b&gt;Hello!&lt;/b&gt; &quot;Hi!&quot; &apos;Oh no&apos;\n}
    tlp = Pidgin2Adium::TextLogParser.new(@html_logfile_path,
                                          @aliases)
    tlp.cleanup(dirty_text).should == clean_text
  end
end
