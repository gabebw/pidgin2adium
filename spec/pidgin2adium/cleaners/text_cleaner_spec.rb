describe Pidgin2Adium::Cleaners::TextCleaner, '.clean' do
  it 'removes \r' do
    expect(clean("\r")).to eq('')
  end

  it 'converts & to &amp;' do
    expect(clean('&')).to eq('&amp;')
  end

  it 'converts < to &lt;' do
    expect(clean('<')).to eq('&lt;')
  end

  it 'converts > to &gt;' do
    expect(clean('>')).to eq('&gt;')
  end

  it 'converts " to &quot;' do
    expect(clean('"')).to eq('&quot;')
  end

  it "converts ' to &apos;" do
    expect(clean("'")).to eq('&apos;')
  end

  def clean(line)
    Pidgin2Adium::Cleaners::TextCleaner.clean(line)
  end
end
