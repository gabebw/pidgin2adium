require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/pidgin2adium.rb'
require 'hanna/rdoctask'

Hoe.plugin :gemcutter
Hoe.plugin :newgem
Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'pidgin2adium' do
  self.developer('Gabe B-W', 'pidgin2adium@brandeis.edu')
  self.extra_rdoc_files = %w{README.rdoc}
  #self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.rubyforge_name       = self.name # this is default value
  # self.extra_deps         = [['activesupport','>= 2.0.2']]
  
  self.spec_extras[:extensions]  = "ext/balance_tags_c/extconf.rb"
end

$hoe.spec.rdoc_options = %w{--main README.rdoc}

# Use hanna RDoc template, if available
begin
    gem "hanna"
    $hoe.spec.rdoc_options << '-T hanna'
rescue GEM::LoadError
    # hanna not installed, continue
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }
task :postrelease => [:publish_docs, :announce]

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
