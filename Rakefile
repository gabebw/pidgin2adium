require 'bundler'
require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :coverage do
  system "COVERAGE=1 rake ; open coverage/index.html"
end

task default: :spec
