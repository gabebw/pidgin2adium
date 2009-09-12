#!/usr/bin/ruby -w

#Author: Gabe Berke-Williams, 2008
#With thanks to Li Ma, whose blog post at
#http://li-ma.blogspot.com/2008/10/pidgin-log-file-to-adium-log-converter.html
#helped tremendously.
#
#A ruby program to convert Pidgin log files to Adium log files, then place
#them in the Adium log directory with allowances for time zone differences.

require 'pidgin2adium/SrcFileParse'
require 'pidgin2adium/ChatFileGenerator'
require 'parsedate'
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
    # put's content. Also put's to @LOG_FILE_FH if @debug == true.
    def Pidgin2Adium.logMsg(str, isError=false)
	content = str.to_s
	if isError == true
	    content= "ERROR: #{str}"
	end
	puts content
    end

    class Logs
	# FILE_EXISTS is returned by ChatFileGenerator.buildDomAndOutput() if the output logfile already exists.
	FILE_EXISTS = 42
	def initialize(src, out, aliases, libdir, tz=nil, debug=false)
	    # These files/directories show up in Dir.entries(x)
	    @BAD_DIRS = %w{. .. .DS_Store Thumbs.db .system}
	    src = File.expand_path(src)
	    out = File.expand_path(out)
	    unless File.directory?(src)
		puts "Source directory #{src} does not exist or is not a directory."
		raise Errno::ENOENT
	    end
	    unless File.directory?(out)
		begin
		    FileUtils.mkdir_p(out)
		rescue
		    puts "Output directory #{out} does not exist or is not a directory and could not be created."
		    raise Errno::ENOENT
		end
	    end

	    if libdir.nil?
		puts "You must provide libdir."
		raise Error
	    end

	    @src_dir = src
	    @out_dir = out

	    # Whitespace is removed for easy matching later on.
	    @my_aliases = aliases.map{|x| x.downcase.gsub(/\s+/,'') }.uniq
	    # @libdir is the directory in
	    # ~/Library/Application Support/Adium 2.0/Users/Default/Logs/.
	    # For AIM, it's like "AIM.<screenname>"
	    @libdir = libdir
	    @debug = debug
	    @DEFAULT_TIME_ZONE = tz || Time.now.zone
	    # local offset, like "-0800" or "+1000"
	    @DEFAULT_TZ_OFFSET = '%+03d00'%Time.zone_offset(@DEFAULT_TIME_ZONE)
	end

	def start
	    Pidgin2Adium.logMsg "Begin converting."
	    begin
		filesPath = getAllChatFilesPath(@src_dir)
	    rescue Errno::EACCES => bang
		Pidgin2Adium.logMsg("Sorry, permission denied for getting chat files from #{@src_dir}.", true)
		Pidgin2Adium.logMsg("Details: #{bang.message}", true)
		raise Errno::EACCES
	    end

	    Pidgin2Adium.logMsg(filesPath.length.to_s + " files to convert.")
	    filesPath.each do |fname|
		Pidgin2Adium.logMsg("Converting #{fname}...")
		convert(fname)
	    end

	    copyLogs()
	    deleteSearchIndexes()

	    Pidgin2Adium.logMsg "Finished converting! Converted #{filesPath.length} files."
	end


	# Problem: imported logs are viewable in the Chat Transcript Viewer, but are not indexed,
	# so a search of the logs doesn't give results from the imported logs.
	# To fix this, we delete the cached log indexes, which forces Adium to re-index.
	def deleteSearchIndexes()
	    Pidgin2Adium.logMsg "Deleting log search indexes in order to force re-indexing of imported logs..."
	    dirtyFile=File.expand_path("~/Library/Caches/Adium/Default/DirtyLogs.plist")
	    logIndexFile=File.expand_path("~/Library/Caches/Adium/Default/Logs.index")
	    [dirtyFile, logIndexFile].each do |f|
		if File.exist?(f)
		    if File.writable?(f)
			File.delete(f)
		    else
			Pidgin2Adium.logMsg("#{f} exists but is not writable. Please delete it yourself.", true)
		    end
		end
	    end
	    Pidgin2Adium.logMsg "...done."
	    Pidgin2Adium.logMsg "When you next start the Adium Chat Transcript Viewer, it will re-index the logs, which may take a while."
	end

	# <tt>convert</tt> creates a new SrcHtmlFileParse or SrcTxtFileParse object,
	# as appropriate, and calls its parse() method.
	# Returns false if there was a problem, true otherwise
	def convert(srcPath)
	    ext = File.extname(srcPath).sub('.', '').downcase
	    if(ext == "html" || ext == "htm")
		srcFileParse = SrcHtmlFileParse.new(srcPath, @out_dir, @my_aliases, @DEFAULT_TIME_ZONE, @DEFAULT_TZ_OFFSET)
	    elsif(ext == "txt")
		srcFileParse = SrcTxtFileParse.new(srcPath, @out_dir, @my_aliases, @DEFAULT_TIME_ZONE, @DEFAULT_TZ_OFFSET)
	    elsif(ext == "chatlog")
		# chatlog FILE, not directory
		Pidgin2Adium.logMsg("Found chatlog FILE - moving to chatlog DIRECTORY.")
		# Create out_dir/log.chatlog/
		begin
		    toCreate = "#{@out_dir}/#{srcPath}" 
		    Dir.mkdir(toCreate)
		rescue => bang
		    Pidgin2Adium.logMsg("Could not create #{toCreate}: #{bang.class} #{bang.message}", true)
		    return false
		end
		fileWithXmlExt = srcPath[0, srcPath.size-File.extname(srcPath).size] + ".xml"
		# @src_dir/log.chatlog (file) -> @out_dir/log.chatlog/log.xml
		File.cp(srcPath, File.join(@out_dir, srcPath, fileWithXmlExt))
		Pidgin2Adium.logMsg("Copied #{srcPath} to " + File.join(@out_dir, srcPath, fileWithXmlExt))
		return true
	    else
		Pidgin2Adium.logMsg("srcPath (#{srcPath}) is not a txt, html, or chatlog file. Doing nothing.")
		return false
	    end

	    chatFG = srcFileParse.parseFile()
	    return false if chatFG == false

	    destFilePath = chatFG.convert()
	    return \
		case destFilePath
		when false
		    Pidgin2Adium.logMsg("Converting #{srcPath} failed.", true); 
		    false
		when FILE_EXISTS
		    Pidgin2Adium.logMsg("File already exists.")
		    true
		else
		    Pidgin2Adium.logMsg("Output to: #{destFilePath}")
		    true
		end
	end

	def getAllChatFilesPath(dir)
	    return [] if File.basename(dir) == ".system"
	    # recurse into each subdir
	    return (Dir.glob(File.join(@src_dir, '**', '*.{html,txt}')) - @BAD_DIRS)
	end

	# Copies logs, accounting for timezone changes
	def copyLogs
	    Pidgin2Adium.logMsg "Copying logs with accounting for different time zones..."
	    real_dest_dir = File.expand_path('~/Library/Application Support/Adium 2.0/Users/Default/Logs/') + '/' + @libdir + '/'
	    real_src_dir = File.join(@out_dir, @libdir) + '/'

	    src_entries =  Dir.entries(real_src_dir)
	    dest_entries =  Dir.entries(real_dest_dir)
	    both_entries = (src_entries & dest_entries) - @BAD_DIRS

	    both_entries.each do |name|
		my_src_entries = Dir.entries(real_src_dir + name) - @BAD_DIRS
		my_dest_entries = Dir.entries(real_dest_dir + name) - @BAD_DIRS

		in_both = my_src_entries & my_dest_entries
		in_both.each do |logdir|
		    FileUtils.cp(
			File.join(real_src_dir, name, logdir, logdir.sub('chatlog', 'xml')),
			File.join(real_dest_dir, name, logdir) + '/',
				 :verbose => false)
		end
		# The logs that are only in one of the dirs are not necessarily different logs than the dest.
		# They might just have different timestamps. Thus, we use regexes.
		only_in_src  = my_src_entries - in_both
		only_in_dest = my_dest_entries - in_both
		# Move files from real_src_dir that are actually in both, but just have different time zones.
		only_in_src.each do |srcLogDir|
		    # Match on everything except the timezone ("-0400.chatlog")
		    fname_beginning_regex = Regexp.new( Regexp.escape(srcLogDir.sub(/-\d{4}.\.chatlog$/, '')) )
		    target_chatlog_dir = only_in_dest.find{|d| d =~ fname_beginning_regex }
		    if target_chatlog_dir.nil?
			# Only in source, so we can copy it without fear of overwriting.
			target_chatlog_dir = srcLogDir
			FileUtils.mkdir_p(File.join(real_dest_dir, name, target_chatlog_dir))
		    end
		    # Move to target_chatlog_dir so we overwrite the destination
		    # file but still use its timestamp
		    # (if it exists; if it doesn't, then we're using our own
		    # timestamp).
		    FileUtils.cp(
			File.join(real_src_dir, name, srcLogDir, srcLogDir.sub('chatlog', 'xml')),
			File.join(real_dest_dir, name, target_chatlog_dir, target_chatlog_dir.sub('chatlog', 'xml')),
			:verbose => false
		    )
		end
	    end
	    Pidgin2Adium.logMsg "Log files copied!"
	end
    end
end
