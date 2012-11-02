require 'spec_helper'

describe Pidgin2Adium::AliasRegistry do
  it 'keeps track of aliases' do
    alias_registry['My Cool Alias'] = 'screen_name88'
    alias_registry['My Cool Alias'].should == 'screen_name88'
  end

  it 'finds aliases even when they are queried with an action' do
    alias_registry['My Cool Alias'] = 'screen_name88'
    alias_registry['***My Cool Alias'].should == 'screen_name88'
  end

  it 'downcases screen names' do
    alias_registry['alias'] = 'UPCASE'
    alias_registry['alias'].should == 'upcase'
  end

  it 'removes space from screen names' do
    alias_registry['alias'] = 'a space'
    alias_registry['alias'].should == 'aspace'
  end

  def alias_registry
    @alias_registry ||= Pidgin2Adium::AliasRegistry.new
  end
end

describe Pidgin2Adium::AliasRegistry, '#key?' do
  it 'returns true if the registry contains the key' do
    alias_registry['present'] = 'yes'
    alias_registry.key?('present').should be_true
  end

  it 'returns true when the alias has an action' do
    alias_registry['My Cool Alias'] = 'screen_name88'
    alias_registry.key?('***My Cool Alias').should be_true
  end

  it 'returns false if the registry does not contain the key' do
    alias_registry.key?('no').should be_false
  end

  def alias_registry
    @alias_registry ||= Pidgin2Adium::AliasRegistry.new
  end
end
