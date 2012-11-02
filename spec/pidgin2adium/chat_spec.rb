require 'spec_helper'

describe Pidgin2Adium::Chat do
  describe '#to_s' do
    it 'converts all lines to strings and joins them' do
      chat = Pidgin2Adium::Chat.new(%w(a b c))
      chat.to_s.should == 'abc'
    end
  end

  it 'is enumerable' do
    chat = Pidgin2Adium::Chat.new(%w(a b c))
    chat.map(&:upcase).should == %w(A B C)
  end
end
