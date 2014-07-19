describe Pidgin2Adium::AliasRegistry do
  it 'keeps track of aliases' do
    alias_registry['My Cool Alias'] = 'screen_name88'
    expect(alias_registry['My Cool Alias']).to eq('screen_name88')
  end

  it 'finds aliases even when they are queried with an action' do
    alias_registry['My Cool Alias'] = 'screen_name88'
    expect(alias_registry['***My Cool Alias']).to eq('screen_name88')
  end

  it 'downcases screen names' do
    alias_registry['alias'] = 'UPCASE'
    expect(alias_registry['alias']).to eq('upcase')
  end

  it 'removes space from screen names' do
    alias_registry['alias'] = 'a space'
    expect(alias_registry['alias']).to eq('aspace')
  end

  it 'takes a default' do
    alias_registry = Pidgin2Adium::AliasRegistry.new('default_name')

    expect(alias_registry['alias']).to eq('default_name')
  end

  it 'normalizes the default' do
    alias_registry = Pidgin2Adium::AliasRegistry.new('DEFAULT NAME')

    expect(alias_registry['alias']).to eq('defaultname')
  end

  def alias_registry
    @alias_registry ||= Pidgin2Adium::AliasRegistry.new('default')
  end
end
