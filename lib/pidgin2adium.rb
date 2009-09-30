#Author: Gabe Berke-Williams, 2008
#With thanks to Li Ma, whose blog post at
#http://li-ma.blogspot.com/2008/10/pidgin-log-file-to-adium-log-converter.html
#helped tremendously.
#
#A ruby program to convert Pidgin log files to Adium log files, then place
#them in the Adium log directory with allowances for time zone differences.

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'pidgin2adium/log_parser'
require 'fileutils'

class Time
    ZoneOffset = {
	'UTC' => 0,
	# ISO 8601
	'Z' => 0,
	# RFC 822
	'UT' => 0, 'GMT' => 0,
	'EST' => -5, 'EDT' => -4,
	'CST' => -6, 'CDT' => -5,
	'MST' => -7, 'MDT' => -6,
	'PST' => -8, 'PDT' => -7,
	# Following definition of military zones is original one.
	# See RFC 1123 and RFC 2822 for the error in RFC 822.
	'A' => +1, 'B' => +2, 'C' => +3, 'D' => +4,  'E' => +5,  'F' => +6, 
	'G' => +7, 'H' => +8, 'I' => +9, 'K' => +10, 'L' => +11, 'M' => +12,
	'N' => -1, 'O' => -2, 'P' => -3, 'Q' => -4,  'R' => -5,  'S' => -6, 
	'T' => -7, 'U' => -8, 'V' => -9, 'W' => -10, 'X' => -11, 'Y' => -12
    }
    # Returns offset in hours, e.g. '+0900'
    def Time.zone_offset(zone, year=Time.now.year)
	off = nil
	zone = zone.upcase
	if /\A([+-])(\d\d):?(\d\d)\z/ =~ zone
	    off = ($1 == '-' ? -1 : 1) * ($2.to_i * 60 + $3.to_i) * 60
	elsif /\A[+-]\d\d\z/ =~ zone
	    off = zone.to_i
	elsif ZoneOffset.include?(zone)
	    off = ZoneOffset[zone]
	elsif ((t = Time.local(year, 1, 1)).zone.upcase == zone rescue false)
	    off = t.utc_offset / 3600
	elsif ((t = Time.local(year, 7, 1)).zone.upcase == zone rescue false)
	    off = t.utc_offset / 3600
	end
	off
    end
end

module Pidgin2Adium
    # FILE_EXISTS is returned by LogGenerator.build_dom_and_output() if the
    # output logfile already exists.
    FILE_EXISTS = 42
    VERSION = "1.0.0"
    # Prints arguments.
    def Pidgin2Adium.log_msg(str, is_error=false)
	content = str.to_s
	if is_error == true
	    content= "ERROR: #{str}"
	end
	puts content
    end

    class LogConverter
	def initialize(src, out, aliases, libdir, tz=nil, debug=false)
	    # These files/directories show up in Dir.entries(x)
	    @BAD_DIRS = %w{. .. .DS_Store Thumbs.db .system}
	    @src_dir = File.expand_path(src)
	    @out_dir = File.expand_path(out)
	    # Whitespace is removed for easy matching later on.
	    @my_aliases = aliases.map{|x| x.downcase.gsub(/\s+/,'') }.uniq
	    # @libdir is the directory in
	    # ~/Library/Application Support/Adium 2.0/Users/Default/Logs/.
	    # For AIM, it's like "AIM.<screenname>"
	    # FIXME: don't make the user pass in libdir - we can and SHOULD change it on a per-service/screenname basis
	    @libdir = libdir
	    @DEFAULT_TIME_ZONE = tz || Time.now.zone
	    @debug = debug
	    unless File.directory?(@src_dir)
		puts "Source directory #{@src_dir} does not exist or is not a directory."
		raise Errno::ENOENT
	    end
	    unless File.directory?(@out_dir)
		begin
		    FileUtils.mkdir_p(@out_dir)
		rescue
		    puts "Output directory #{@out_dir} does not exist or is not a directory and could not be created."
		    raise Errno::ENOENT
		end
	    end

	    # local offset, like "-0800" or "+1000"
	    @DEFAULT_TZ_OFFSET = '%+03d00'%Time.zone_offset(@DEFAULT_TIME_ZONE)
	end

	def start
	    Pidgin2Adium.log_msg "Begin converting."
	    begin
		files_path = get_all_chat_files(@src_dir)
	    rescue Errno::EACCES => bang
		Pidgin2Adium.log_msg("Sorry, permission denied for getting Pidgin chat files from #{@src_dir}.", true)
		Pidgin2Adium.log_msg("Details: #{bang.message}", true)
		raise Errno::EACCES
	    end

	    Pidgin2Adium.log_msg("#{files_path.length} files to convert.")
	    total_files = files_path.size
	    files_path.each_with_index do |fname, i|
		Pidgin2Adium.log_msg(
		    sprintf("[%d/%d] Converting %s...",
			(i+1), total_files, fname)
		)
		convert(fname)
	    end

	    copy_logs()
	    delete_search_indexes()

	    Pidgin2Adium.log_msg "Finished converting! Converted #{files_path.length} files."
	end


	# Here is the problem: imported logs are viewable in the Adium Chat
	# Transcript Viewer, but are not indexed, so a search of the logs
	# doesn't give results from the imported logs. To fix this, we delete
	# the cached log indexes, which forces Adium to re-index.
	def delete_search_indexes()
	    Pidgin2Adium.log_msg "Deleting log search indexes in order to force re-indexing of imported logs..."
	    dirty_file=File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
	    log_index_file=File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
	    [dirty_file, log_index_file].each do |f|
		if File.exist?(f)
		    if File.writable?(f)
			File.delete(f)
		    else
			Pidgin2Adium.log_msg("#{f} exists but is not writable. Please delete it yourself.", true)
		    end
		end
	    end
	    Pidgin2Adium.log_msg "...done."
	    Pidgin2Adium.log_msg "When you next start the Adium Chat Transcript Viewer, it will re-index the logs, which may take a while."
	end

	# Create a new HtmlLogParser or TextLogParser object
	# (as appropriate) and calls its parse() method.
	# Returns false if there was a problem, true otherwise.
	def convert(src_path)
	    ext = File.extname(src_path).sub('.', '').downcase
	    if(ext == "html" || ext == "htm")
		parser = HtmlLogParser.new(src_path, @out_dir, @my_aliases, @DEFAULT_TIME_ZONE, @DEFAULT_TZ_OFFSET)
	    elsif(ext == "txt")
		parser = TextLogParser.new(src_path, @out_dir, @my_aliases, @DEFAULT_TIME_ZONE, @DEFAULT_TZ_OFFSET)
	    elsif(ext == "chatlog")
		# chatlog FILE, not directory
		Pidgin2Adium.log_msg("Found chatlog FILE - moving to chatlog DIRECTORY.")
		# Create out_dir/log.chatlog/
		begin
		    to_create = "#{@out_dir}/#{src_path}" 
		    Dir.mkdir(to_create)
		rescue => bang
		    Pidgin2Adium.log_msg("Could not create #{to_create}: #{bang.class} #{bang.message}", true)
		    return false
		end
		file_with_xml_ext = src_path[0, src_path.size-File.extname(src_path).size] << ".xml"
		# @src_dir/log.chatlog (file) -> @out_dir/log.chatlog/log.xml
		File.cp(src_path, File.join(@out_dir, src_path, file_with_xml_ext))
		Pidgin2Adium.log_msg("Copied #{src_path} to " << File.join(@out_dir, src_path, file_with_xml_ext))
		return true
	    else
		Pidgin2Adium.log_msg("src_path (#{src_path}) is not a txt, html, or chatlog file. Doing nothing.")
		return false
	    end

	    generator = parser.parse_file()
	    return false if generator == false

	    dest_file_path = generator.convert()
	    return \
		case dest_file_path
		when false
		    Pidgin2Adium.log_msg("Converting #{src_path} failed.", true); 
		    false
		when Pidgin2Adium::FILE_EXISTS
		    Pidgin2Adium.log_msg("File already exists.")
		    true
		else
		    Pidgin2Adium.log_msg("Output to: #{dest_file_path}")
		    true
		end
	end

	# Returns an array of all .htm, .html, and .txt files in provided path.
	def get_all_chat_files(dir)
	    return [] if File.basename(dir) == ".system"
	    # recurse into each subdir
	    return (Dir.glob(File.join(@src_dir, '**', '*.{htm,html,txt}')) - @BAD_DIRS)
	end

	# Copies logs with allowance for timezone changes.
	def copy_logs
	    Pidgin2Adium.log_msg "Copying logs with accounting for different time zones..."
	    # FIXME: not all logs are AIM logs, libdir may change
	    src_dir = File.join(@out_dir, @libdir) << '/'
	    dest_dir = File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') << "/#{@libdir}/"

	    src_entries =  Dir.entries(src_dir)
	    dest_entries =  Dir.entries(dest_dir)
	    both_entries = (src_entries & dest_entries) - @BAD_DIRS

	    both_entries.each do |name|
		my_src_entries = Dir.entries(src_dir << name) - @BAD_DIRS
		my_dest_entries = Dir.entries(dest_dir << name) - @BAD_DIRS

		in_both = my_src_entries & my_dest_entries
		# Copy files 
		in_both.each do |logdir|
		    FileUtils.cp(
			File.join(src_dir, name, logdir, logdir.sub('chatlog', 'xml')),
			File.join(dest_dir, name, logdir) << '/',
				 :verbose => false)
		end
		# The logs that are only in one of the dirs are not necessarily
		# different logs than the dest.  They might just have different
		# timestamps. Thus, we use regexes.
		only_in_src  = my_src_entries - in_both
		only_in_dest = my_dest_entries - in_both
		# Move files from src_dir that are actually in both, but
		# just have different time zones.
		only_in_src.each do |src_log_dir|
		    # Match on everything except the timezone ("-0400.chatlog")
		    file_begin_regex = Regexp.new('^'<<Regexp.escape(src_log_dir.sub(/-\d{4}.\.chatlog$/, '')) )
		    target_chatlog_dir = only_in_dest.find{|d| d =~ file_begin_regex}
		    if target_chatlog_dir.nil?
			# Really only in source, so we can copy it without fear of
			# overwriting.
			target_chatlog_dir = src_log_dir
			FileUtils.mkdir_p(File.join(dest_dir, name, target_chatlog_dir))
		    else
			puts "!!! #{target_chatlog_dir}"
		    end
		    # If the target file exists, then we are overwriting its content but keeping its name.
		    # If it doesn't, then there's no problem anyway.
		    FileUtils.cp(
			File.join(src_dir, name, src_log_dir, src_log_dir.sub('chatlog', 'xml')),
			File.join(dest_dir, name, target_chatlog_dir, target_chatlog_dir.sub('chatlog', 'xml')),
			:verbose => false
		    )
		end
	    end
	    Pidgin2Adium.log_msg "Log files copied!"
	end
    end
end
