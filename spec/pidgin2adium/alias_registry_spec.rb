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

  it 'takes a default' do
    alias_registry = Pidgin2Adium::AliasRegistry.new('default_name')

    alias_registry['alias'].should == 'default_name'
  end

  it 'normalizes the default' do
    alias_registry = Pidgin2Adium::AliasRegistry.new('DEFAULT NAME')

    alias_registry['alias'].should == 'defaultname'
  end

  def alias_registry
    @alias_registry ||= Pidgin2Adium::AliasRegistry.new('default')
  end
end
