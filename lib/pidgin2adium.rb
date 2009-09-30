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
require 'tmpdir'

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
    VERSION = "2.0.0"
    ERROR_MAJOR = 'ERROR_MAJOR'
    ERROR_MINOR = 'ERROR_MINOR'
    # Prints arguments.
    def log_msg(str, error_level=nil)
	content = str.to_s
	unless error_level.nil?
	    if error_level == ERROR_MAJOR
		content = "ERROR: #{str}"
	    elsif error_level == ERROR_MINOR
		content = "Oops: #{str}"
	    end
	end
	puts content
    end

    class LogConverter
	include Pidgin2Adium
	def initialize(pidgin_log_dir, aliases, tz=nil, debug=false, user_temp_dir=nil)
	    # These files/directories show up in Dir.entries()
	    @bad_dirs = %w{. .. .DS_Store Thumbs.db .system}
	    @pidgin_log_dir = File.expand_path(pidgin_log_dir)
	    # Whitespace is removed for easy matching later on.
	    @my_aliases = aliases.map{|x| x.downcase.gsub(/\s+/,'') }.uniq
	    @default_time_zone = tz || Time.now.zone
	    @debug = debug
	    # Optional dir to place converted logs instead of in Adium location
	    @user_temp_dir = user_temp_dir

	    @adium_log_dir = File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') << '/' 
	    @temp_dir = "#{Dir::tmpdir}/pidgin2adium/"
	    unless File.directory? @temp_dir
		FileUtils.mkdir(@temp_dir)
		unless File.directory? @temp_dir
		    puts "Could not create temp folder #{@temp_dir}. Check permissions?"
		    exit 1
		end
	    end
	    unless File.directory?(@pidgin_log_dir)
		puts "Source directory #{@pidgin_log_dir} does not exist or is not a directory."
		raise Errno::ENOENT
	    end
	    unless File.directory?(@adium_log_dir)
		puts "Adium log directory (#{@adium_log_dir}) does not exist or is not a directory. Is Adium installed?"
		raise Errno::ENOENT
	    end

	    # local offset, like "-0800" or "+1000"
	    @default_tz_offset = '%+03d00'%Time.zone_offset(@default_time_zone)
	end

	def start
	    log_msg "Begin converting."
	    begin
		files_path = get_all_chat_files(@pidgin_log_dir)
	    rescue Errno::EACCES => bang
		log_msg("Sorry, permission denied for getting Pidgin chat files from #{@pidgin_log_dir}.", ERROR_BAD)
		log_msg("Details: #{bang.message}", ERROR_MAJOR)
		raise Errno::EACCES
	    end

	    log_msg("#{files_path.length} files to convert.")
	    total_files = files_path.size
	    files_path.each_with_index do |fname, i|
		log_msg(
		    sprintf("[%d/%d] Converting %s...",
			(i+1), total_files, fname)
		)
		convert(fname)
	    end

	    copy_logs()
	    delete_search_indexes()

	    log_msg "Finished converting! Converted #{files_path.length} files."
	end


	# Here is the problem: imported logs are viewable in the Adium Chat
	# Transcript Viewer, but are not indexed, so a search of the logs
	# doesn't give results from the imported logs. To fix this, we delete
	# the cached log indexes, which forces Adium to re-index.
	def delete_search_indexes()
	    log_msg "Deleting log search indexes in order to force re-indexing of imported logs..."
	    dirty_file=File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
	    log_index_file=File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
	    [dirty_file, log_index_file].each do |f|
		if File.exist?(f)
		    if File.writable?(f)
			File.delete(f)
		    else
			log_msg("#{f} exists but is not writable. Please delete it yourself.", ERROR_BAD)
		    end
		end
	    end
	    log_msg "...done."
	    log_msg "When you next start the Adium Chat Transcript Viewer, it will re-index the logs, which may take a while."
	end

	# Create a new HtmlLogParser or TextLogParser object
	# (as appropriate) and calls its parse() method.
	# Returns false if there was a problem, true otherwise.
	def convert(logfile)
	    ext = File.extname(logfile).sub('.', '').downcase
	    if(ext == "html" || ext == "htm")
		# def initialize(src_path, dest_dir_base, user_aliases, user_tz, user_tz_offset)
		parser = HtmlLogParser.new(logfile, @adium_log_dir, @my_aliases, @default_time_zone, @default_tz_offset)
	    elsif(ext == "txt")
		parser = TextLogParser.new(logfile, @adium_log_dir, @my_aliases, @default_time_zone, @default_tz_offset)
	    elsif(ext == "chatlog")
		log_msg("Found chatlog FILE - moving to chatlog DIRECTORY.")
		# Create out_dir/log.chatlog/
		begin
		    chatlog_directory = "#{@adium_log_dir}/#{logfile}" 
		    Dir.mkdir(chatlog_directory)
		rescue => bang
		    log_msg("Could not create #{chatlog_directory}: #{bang.class} #{bang.message}", ERROR_BAD)
		    return false
		end
		# @pidgin_log_dir/log.chatlog (file) -> @adium_log_dir/log.chatlog/log.xml
		adium_destination = File.join(@adium_log_dir, logfile, logfile[0, logfile.size-File.extname(logfile).size] << ".xml")
		File.cp(logfile, adium_destination)
		log_msg("Copied #{logfile} to #{adium_destination}")
		return true
	    else
		log_msg("logfile (#{logfile}) is not a txt, html, or chatlog file. Doing nothing.")
		return false
	    end

	    generator = parser.parse_file()
	    return false if generator == false

	    dest_file_path = generator.convert()
	    return \
		case dest_file_path
		when false
		    log_msg("Converting #{logfile} failed.", ERROR_OOPS); 
		    false
		when FILE_EXISTS
		    log_msg("File already exists.")
		    true
		else
		    log_msg("Output to: #{dest_file_path}")
		    true
		end
	end

	# Returns an array of all .htm, .html, and .txt files in provided path.
	def get_all_chat_files(dir)
	    return [] if File.basename(dir) == ".system"
	    # recurse into each subdir
	    return (Dir.glob("#{@pidgin_log_dir}/**/*.{htm,html,txt}") - @bad_dirs)
	end

	# Copies logs from temporary dir into Adium's log folder with allowance
	# for timezone differences. This means that a file in Adium's log folder
	# called "log-file-0400PDT.html" is perceived as the same file as a
	# newly converted file called "log-file-0300CST.html" and so Adium's
	# log file will be overwritten. Of course, files are much more
	# intricately named than "log-file.html" and so this does not overwrite
	# the wrong files.
	def copy_logs
	    log_msg "Copying logs with accounting for different time zones..."
	    # Loop over the service/screenname combos ("AIM.buddyname")
	    Dir.glob("#{@temp_dir}/*") do |account_dir|
		p account_dir
		dest_dir = @adium_log_dir << File.basename(account_dir) << '/'
		src_buddy_folders =  Dir.entries(account_dir)
		dest_buddy_folders =  Dir.entries(dest_dir)
		both_buddy_folders = (src_buddy_folders & dest_buddy_folders) - @bad_dirs

		both_buddy_folders.each do |buddy|
		    my_src_buddy_files = Dir.entries(account_dir << buddy) - @bad_dirs
		    my_dest_buddy_files = Dir.entries(dest_dir << buddy) - @bad_dirs
		    buddies_in_both = my_src_buddy_files & my_dest_buddy_files
		    puts "buddy: #{buddy}"
		    puts "buddies_in_both: #{buddies_in_both}"
		    my_src_buddy_files = Dir.entries(account_dir << buddy) - @bad_dirs
		    # Copy files 
		    buddies_in_both.each do |logfile|
			puts "logfile: #{logfile}"
			FileUtils.cp(
			    File.join(account_dir, buddy, logfile, logfile.sub('chatlog', 'xml')),
			    File.join(dest_dir, buddy, logfile) << '/',
			    :verbose => false)
		    end
		    # The logs that are only in one of the dirs are not
		    # necessarily different logs than the dest.  They might
		    # just have different timestamps. Thus, we use regexes.
		    buddies_only_in_src  = my_src_buddy_files - buddies_in_both
		    buddies_only_in_dest = my_dest_buddy_files - buddies_in_both
		    
		    # Move files from @temp_dir that are actually in both, but
		    # just have different time zones.
		    buddies_only_in_src.each do |src_buddy_dir|
			puts "src_buddy_dir: #{src_buddy_dir}"
			# Match everything except the timezone ("-0400.chatlog")
			file_begin_regex = Regexp.new('^'<<Regexp.escape(src_buddy_dir.sub(/-\d{4}.\.chatlog$/, '')) )
			target_chatlog_dir = buddies_only_in_dest.find{|d| d =~ file_begin_regex}
			if target_chatlog_dir.nil?
			    # Really only in source, so we can copy it without
			    # fear of overwriting.
			    target_chatlog_dir = src_buddy_dir
			    FileUtils.mkdir_p(File.join(dest_dir, name, target_chatlog_dir))
			else
			    puts "!!! #{target_chatlog_dir}"
			end
			# If the target file exists, then we are overwriting
			# its content but keeping its name.
			# If it doesn't, then there's no problem anyway.
			FileUtils.cp(
			    File.join(src_dir, name, src_log_dir, src_log_dir.sub('chatlog', 'xml')),
			    File.join(dest_dir, name, target_chatlog_dir, target_chatlog_dir.sub('chatlog', 'xml')),
			    :verbose => false
			)
		    end
		end
		log_msg "Log files copied!"
	    end
	end
    end
end
