# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pidgin2adium/version"

Gem::Specification.new do |s|
  s.name             = "pidgin2adium"
  s.date             = Date.today.strftime('%Y-%m-%d')
  s.version          = Pidgin2Adium::VERSION
  s.platform         = Gem::Platform::RUBY
  s.authors          = ["Gabe Berke-Williams"]
  s.email            = "gbw@brandeis.edu"
  s.description      = "Pidgin2Adium is a fast, easy way to convert Pidgin (formerly gaim) logs to the Adium format."
  s.summary          = "Pidgin2Adium is a fast, easy way to convert Pidgin (formerly gaim) logs to the Adium format"
  s.extensions       = ["ext/balance_tags_c/extconf.rb"]
  s.extra_rdoc_files = ["ChangeLog", "LICENSE", "README.rdoc" ]
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.homepage         = "http://github.com/gabebw/pidgin2adium"
  s.require_paths    = ["lib"]

  s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
  s.add_development_dependency(%q<bourne>, ["~> 1.1.1"])
  s.add_development_dependency('rake')
end
