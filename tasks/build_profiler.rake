desc "Build RubyProf version of pidgin2adium script"
task :build_profiler do |t|
    # base = location of Rakefile, e.g. repo base
    base = Dir.pwd
    orig_lines = File.readlines("#{base}/bin/pidgin2adium")
    # remove "log_converter.start" line so we can surround it with RubyProf
    lastline = orig_lines.pop
    orig_text = orig_lines.join
    
    prof_file = File.new("#{base}/bin/pidgin2adium_profiler", 'w')
new_text = <<EOF
require 'ruby-prof'
RubyProf.start
log_converter.start
result = RubyProf.stop
printer = RubyProf::GraphHtmlPrinter.new(result)
highest = Dir.glob('profiler_result*').sort.last
if highest.nil?
    # This is the first profiler html created
    fname = "profiler_result.html"
    f = File.new(fname, 'w')
else
    match = highest.match(/(\d+)/)
    if match
	num = match.captures.last.to_i + 1
	fname = "profiler_result%d.html" % num
	f = File.new(fname, 'w')
    else
	puts "!!! Oops, no match but there is definitely a profile file that exists. Unsure what happened. Outputting to stdout."
	f = STDOUT
    end
end
printer.print(f, {:filename => nil})
EOF
    prof_file.write(orig_text)
    prof_file.write(new_text)
    prof_file.close
end

desc "Set profiler to blank file"
task :clear_profiler do
    base = Dir.pwd
    x = File.new("#{base}/bin/pidgin2adium_profiler", 'w')
    x.puts
    x.close
end

desc "Install debug version of gem, with profiler. Clears profiler file after installing."
task :install_debug => [:build_profiler, :install_gem, :clear_profiler]
