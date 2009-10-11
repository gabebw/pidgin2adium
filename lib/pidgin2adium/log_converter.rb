require 'pidgin2adium'

module Pidgin2Adium
    # An easy way to batch-process a directory. Used by the pidgin2adium
    # command-line script.
    class LogConverter
	include Pidgin2Adium
	# You can add options using the _opts_ hash, which can have the
	# following keys, all of which are optional:
	# * *overwrite*: If true, then overwrite even if log is found.
	#   Defaults to false.
	# * *output_dir*: The top-level dir to put the logs in.
	#   Logs under output_dir are still each in their own folders, etc.
	#   Defaults to Pidgin2Adium::ADIUM_LOG_DIR
	def initialize(pidgin_log_dir, aliases, opts = {})
	    # parse_and_generate will process it for us
	    @opts = opts

	    @pidgin_log_dir = File.expand_path(pidgin_log_dir)
	    @my_aliases = aliases

	    unless File.directory?(@pidgin_log_dir)
		puts "Source directory #{@pidgin_log_dir} does not exist or is not a directory."
		raise Errno::ENOENT
	    end
	end

	# Runs Pidgin2Adium::parse_and_generate on every log file in directory
	# provided in new, then deletes Adium's search indexes to force
	# it to rescan logs on startup.
	def start
	    log_msg "Begin converting."
	    begin
		files_path = get_all_chat_files(@pidgin_log_dir)
	    rescue Errno::EACCES => bang
		error("Sorry, permission denied for getting Pidgin chat files from #{@pidgin_log_dir}.")
		error("Details: #{bang.message}")
		raise Errno::EACCES
	    end

	    total_files = files_path.size
	    total_successes = 0
	    log_msg("#{total_files} files to convert.")
	    files_path.each_with_index do |fname, i|
		log_msg(
		    sprintf("[%d/%d] Converting %s...",
			(i+1), total_files, fname)
		)
		result = parse_and_generate(fname, @my_aliases, @opts)
		total_successes += 1 if result == true
	    end

	    delete_search_indexes()

	    log_msg "Finished converting! Converted #{total_successes} files of #{total_files} total."
	end

	###########
	private
	###########

	def get_all_chat_files(dir)
	    return [] if File.basename(dir) == ".system"
	    # recurse into each subdir
	    return (Dir.glob("#{@pidgin_log_dir}/**/*.{htm,html,txt}") - BAD_DIRS)
	end
    end
end
