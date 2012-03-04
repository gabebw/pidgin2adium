# vim: ft=ruby syntax=ruby
if ENV["COVERAGE"]
  SimpleCov.start do
    add_filter "/spec/"
  end
end
