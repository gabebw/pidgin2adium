describe Pidgin2Adium::Cleaners::TextCleaner, '.clean' do
  it 'removes \r' do
    clean("\r").should == ''
  end

  it 'converts & to &amp;' do
    clean('&').should == '&amp;'
  end

  it 'converts < to &lt;' do
    clean('<').should == '&lt;'
  end

  it 'converts > to &gt;' do
    clean('>').should == '&gt;'
  end

  it 'converts " to &quot;' do
    clean('"').should == '&quot;'
  end

  it "converts ' to &apos;" do
    clean("'").should == '&apos;'
  end

  def clean(line)
    Pidgin2Adium::Cleaners::TextCleaner.clean(line)
  end
end
