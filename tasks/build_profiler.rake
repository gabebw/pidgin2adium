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
else
    match = highest.match(/(d+)/)
    if match
	num = match.captures.last + 1
    end
    fname = "profiler_result%d.html" % num
end
f = File.new(fname, 'w')
printer.print(f, {:filename => nil})
f.close
EOF
    prof_file.write(orig_text)
    prof_file.write(new_text)
    prof_file.close
end

desc "Install debug version of gem, with profiler"
task :install_debug => [:install_gem, :build_profiler]
