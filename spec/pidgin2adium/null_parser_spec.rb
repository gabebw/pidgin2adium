describe Pidgin2Adium::NullParser do
  context '#parse' do
    it 'does nothing' do
      lambda do
        Pidgin2Adium::NullParser.new('path/to/file', 'alias').parse
      end.should_not raise_error
    end

    it 'returns falsy' do
      Pidgin2Adium::NullParser.new('path/to/file', 'alias').parse.should_not be
    end
  end
end
