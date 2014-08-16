require 'simplecov'

$LOAD_PATH.unshift(File.expand_path('..',  __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'pidgin2adium'
require "fakefs/spec_helpers"

Dir['spec/support/**/*.rb'].each { |f| require File.expand_path(f) }

SPEC_ROOT = File.dirname(__FILE__)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def path_to_file
    File.join(path_to_directory, "gabebw", "in.html")
  end

  def path_to_directory
    File.expand_path("./in-logs/")
  end
end
