# Wrap it in a lambda so that we can pass it to Spork.prefork, if spork is installed.
prefork_block = lambda do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

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
     config.before(:all) do
       @current_dir = File.dirname(__FILE__)
       @aliases = %w{gabebw gabeb-w gbw me}.join(',')

       @logfile_path = File.join(@current_dir, "logfiles/")
     end
   end
end

begin
  require 'rubygems'
  require 'spork'
  Spork.prefork(&prefork_block)
  Spork.each_run do
    # This code will be run each time you run your specs.
  end
rescue LoadError
  puts 'To make the tests run faster, run "sudo gem install spork" then run "spork"'
  puts 'from the base pidgin2adium directory.'
  # Spork isn't installed.
  prefork_block.call
end
