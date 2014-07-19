# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pidgin2adium/version"

Gem::Specification.new do |spec|
  spec.name          = "pidgin2adium"
  spec.version       = Pidgin2Adium::VERSION
  spec.authors       = ["Gabe Berke-Williams"]
  spec.email         = "gabe@thoughtbot.com"
  spec.description   = "A fast, easy way to convert Pidgin (gaim) logs to the Adium format."
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/gabebw/pidgin2adium"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.2")

  spec.add_development_dependency("mocha")
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("simplecov")
end
