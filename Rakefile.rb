#!/usr/bin/ruby

require 'rubygems'
require 'rake/gempackagetask'

# Spec reference:
# http://docs.rubygems.org/read/chapter/20
darwin_spec = Gem::Specification.new do |s|
    # Require Mac OS X
    s.platform = Gem::Platform::CURRENT
    s.name = 'pidgin2adium'
    s.version = '1.0.0'
    # Summary is required
    s.summary = "Converts Pidgin logs to Adium format and makes them available to Adium."
    s.description = %q{
      Converts Pidgin logs to Adium format and makes them available to Adium. Works through a shell script, pidgin2adium_logs.
    }.gsub(/\s{2,}/, '')
    s.author = "Gabe B-W"
    s.email = "gbw@rubyforge.org"
    s.homepage = 'http://pidgin2adium.rubyforge.org'
    s.files = Dir["lib/*.rb"].to_a
    s.executables = %w{pidgin2adium_logs}
    s.rubyforge_project = "pidgin2adium"
    # default: false
    s.has_rdoc = false 
end

# Just change the platform
ruby_spec = darwin_spec.clone
ruby_spec.platform = Gem::Platform::RUBY

# http://rake.rubyforge.org/classes/Rake/PackageTask.html
[ruby_spec, darwin_spec].each do |spec|
    Rake::GemPackageTask.new(spec) do |pkg|
	# Create a gzipped tar package
	pkg.need_tar = true
    end
end

task :default => [:package]
