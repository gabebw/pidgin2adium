module Pidgin2Adium
    class LogGenerator
	include Pidgin2Adium
	def initialize(service, user_SN, partner_SN, adium_chat_time_start, dest_dir_base, force=false)
	    # service is used below
	    @user_SN = user_SN
	    @partner_SN = partner_SN
	    @adium_chat_time_start = adium_chat_time_start
	    @dest_dir_base = dest_dir_base
	    # Should we generate a log file even though it exists?
	    @force = force

	    # key is for Pidgin, value is for Adium
	    # Just used for <service>.<screenname> in directory structure
	    @SERVICE_NAME_MAP = {'aim' => 'AIM',
		'jabber' =>'jabber',
		'gtalk'=> 'GTalk',
		'icq' => 'ICQ',
		'qq' => 'QQ',
		'msn' => 'MSN',
		'yahoo' => 'Yahoo'}
	    
	    @service_name = @SERVICE_NAME_MAP[service.downcase]
	    dest_dir_real = File.join(@dest_dir_base, "#{@service_name}.#{@user_SN}", @partner_SN, "#{@partner_SN} (#{@adium_chat_time_start}).chatlog")
	    FileUtils.mkdir_p(dest_dir_real)
	    @dest_file_path = dest_dir_real << '/' << "#{@partner_SN} (#{@adium_chat_time_start}).xml"
	end

	# :nodoc:
	def file_exists?
	    return File.exist?(@dest_file_path)
	end

	# Given an array of Message, Status, and/or Event objects created by LogParser, generates
	# Returns path of output file.
	def generate(chat_array)
	    if not @force
		return FILE_EXISTS if file_exists?
	    end
	    all_msgs = ""
	    # TODO: inject? map! ?
	    chat_array.each { |obj| all_msgs << obj.to_s }
	    
	    outfile = File.new(@dest_file_path, 'w')
	    # no \n before </chat> because all_msgs has it already
	    outfile.printf('<?xml version="1.0" encoding="UTF-8" ?>'<<"\n"+
		   '<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="%s" service="%s">'<<"\n"<<'%s</chat>',
		   @user_SN, @service_name, all_msgs)
	    outfile.close
	    return @dest_file_path
	end
    end
end
