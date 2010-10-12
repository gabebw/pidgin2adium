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
    gem.add_development_dependency(%q<rspec>, [">= 1.3.0"])
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  # RSpec 2
  gem "rspec", ">= 2.0.0"
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
rescue Gem::LoadError
  # RSpec 1
  gem "rspec", "~> 1.3.0"
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end

  Spec::Rake::SpecTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
rescue Gem::LoadError => bang
  puts "!! Please install RSpec: `gem install rspec`"
  raise bang
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
