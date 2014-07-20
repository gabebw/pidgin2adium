require 'simplecov'

$LOAD_PATH.unshift(File.expand_path('..',  __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'fileutils'
require 'pidgin2adium'

Dir['spec/support/**/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
