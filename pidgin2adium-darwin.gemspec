#!/usr/bin/ruby

# Spec reference:
# http://docs.rubygems.org/read/chapter/20

spec = Gem::Specification.new do |s|
  # Require Mac OS X
  s.platform = 'universal-darwin'
  s.name = 'pidgin2adium'
  s.version = '1.0.0'
  # Summary is required
  s.summary = "Converts Pidgin logs and statuses to Adium format and makes them available to Adium."
  s.description = %q{
      Converts Pidgin logs and statuses to Adium format and makes them available to Adium. Also installs
      two shell scripts, pidgin2adium_logs and pidgin2adium_status.
  }.gsub(/\s{2,}/, '')
  s.author = "Gabe B-W"
  s.email = "gbw@rubyforge.org"
  s.homepage = 'http://pidgin2adium.rubyforge.org'
  s.files = Dir["lib/**/*.rb"].to_a
  #s.require_paths = %w{lib}
  s.executables = %w{
      pidgin2adium_logs
      pidgin2adium_status
  }
  s.rubyforge_project = "pidgin2adium"
  s.has_rdoc = false 
end
