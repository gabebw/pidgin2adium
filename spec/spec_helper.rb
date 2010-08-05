$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'ext', 'balance_tags_c'))

require 'pidgin2adium'
require 'faker'

begin
  # RSpec 2
  gem 'rspec', '>= 2.0.0.beta.18'
  require 'rspec'
  constant = RSpec
rescue Gem::LoadError
  # RSpec 1
  gem 'rspec', '~> 1.3'
  require 'spec'
  require 'spec/autorun'
  constant = Spec::Runner
end

constant.configure do |config|
end
