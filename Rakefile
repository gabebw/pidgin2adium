require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pidgin2adium"
    gem.summary = %Q{Pidgin2Adium is a fast, easy way to convert Pidgin (formerly gaim) logs to the Adium format}
    gem.description = %Q{Pidgin2Adium is a fast, easy way to convert Pidgin (formerly gaim) logs to the Adium format.}
    gem.email = "gbw@brandeis.edu"
    gem.homepage = "http://github.com/gabebw/pidgin2adium"
    gem.authors = ["Gabe Berke-Williams"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.add_bundler_dependencies
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  # RSpec 2
  gem "rspec", ">= 2.0.0.beta.18"
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.spec_opts << %w{-Ilib -Ispec}
    spec.pattern = 'spec/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.spec_opts << %w{-Ilib -Ispec}
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
rescue Gem::LoadError
  # RSpec 1
  gem "rspec"
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
end

task :spec => :check_dependencies
task :spec => "extconf:compile"

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "pidgin2adium #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Dir['tasks/**/*.rake'].each { |t| load t }
