require 'rubygems'
require 'rake'
require './lib/version.rb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pidgin2adium"
    gem.version = Pidgin2Adium::VERSION
    gem.summary = %Q{Pidgin2Adium is a fast, easy way to convert Pidgin (formerly gaim) logs to the Adium format}
    gem.description = %Q{Pidgin2Adium is a fast, easy way to convert Pidgin (formerly gaim) logs to the Adium format.}
    gem.email = "gbw@brandeis.edu"
    gem.homepage = "http://github.com/gabebw/pidgin2adium"
    gem.authors = ["Gabe Berke-Williams"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.add_development_dependency(%q<bundler>, [">= 1.0.0"])
    gem.add_development_dependency(%q<jeweler>, [">= 0"])
    gem.add_development_dependency(%q<rspec>, ["~> 2.4.0"])
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

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

task :spec => :check_dependencies
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
