$LOAD_PATH.unshift(File.expand_path('..',  __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

begin
  require 'simplecov'
rescue LoadError
  # Ignore, we're probably on 1.8.7
end

require 'fileutils'
require 'pidgin2adium'
require 'bourne'

Dir['spec/support/**/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.mock_with :mocha
  config.before(:all) do
    @spec_directory = File.dirname(__FILE__)

    @logfile_path = File.join(@spec_directory, "support", "logfiles")
    @text_logfile_path = "#{@logfile_path}/2006-12-21.223606.txt"
    @htm_logfile_path = "#{@logfile_path}/2008-01-15.071445-0500PST.htm"
    @html_logfile_path = "#{@logfile_path}/2008-01-15.071445-0500PST.html"

    @output_dir = File.join(@spec_directory, "output-dir/")
  end
end
