describe Pidgin2Adium::NullParser do
  context '#parse' do
    it 'does nothing' do
      expect do
        Pidgin2Adium::NullParser.new('path/to/file', 'alias').parse
      end.not_to raise_error
    end

    it 'returns falsy' do
      expect(Pidgin2Adium::NullParser.new('path/to/file', 'alias').parse).not_to be
    end
  end
end
