require 'simplecov'

$LOAD_PATH.unshift(File.expand_path('..',  __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'fileutils'
require 'pidgin2adium'
require 'mocha/api'

Dir['spec/support/**/*.rb'].each { |f| require File.expand_path(f) }

SPEC_DIRECTORY = File.dirname(__FILE__)

RSpec.configure do |config|
  config.mock_with :mocha

  def fixture_path
    Pathname.new(File.join(SPEC_DIRECTORY, 'support', 'fixtures'))
  end
end
