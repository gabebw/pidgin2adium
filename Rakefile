require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = %w{-Ilib -Ispec}
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rspec_opts = %w{-Ilib -Ispec}
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => "extconf:compile"

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = Pidgin2Adium::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "pidgin2adium #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Dir['tasks/**/*.rake'].each { |t| load t }
