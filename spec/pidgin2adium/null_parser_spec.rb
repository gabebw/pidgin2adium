require 'spec_helper'

describe Pidgin2Adium::NullParser do
  context '#parse' do
    it 'does nothing' do
      lambda do
        Pidgin2Adium::NullParser.new('path/to/file', %w(alias)).parse
      end.should_not raise_error
    end
  end
end
