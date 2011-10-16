namespace :extconf do
  desc "Compiles the Ruby extension"
  task :compile
end

task :compile => "extconf:compile"

task :rspec => :compile
