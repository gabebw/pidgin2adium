# ADD DOCUMENTATION
require 'balance-tags.rb'

module Pidgin2Adium
    class ChatFileGenerator
	def initialize(service, user_SN, partner_SN, adium_chat_time_start, dest_dir_base)
	    @service = service
	    @user_SN = user_SN
	    @partner_SN = partner_SN
	    @adium_chat_time_start = adium_chat_time_start
	    @dest_dir_base = dest_dir_base

	    # @chat_lines is an array of Message, Status, and Event objects
	    @chat_lines = []
	    # key is for Pidgin, value is for Adium
	    # Just used for <service>.<screenname> in directory structure
	    @SERVICE_NAME_MAP = {'aim' => 'AIM',
		'jabber' =>'jabber',
		'gtalk'=> 'GTalk',
		'icq' => 'ICQ',
		'qq' => 'QQ',
		'msn' => 'MSN',
		'yahoo' => 'Yahoo'}
	end

	# Add a line to @chat_lines.
	# It is its own method because attr_writer creates the method
	# 'chat_message=', which doesn't help for chat_message.push
	def append_line(line)
	    @chat_lines.push(line)
	end

	# Returns path of output file
	def convert()
	    service_name = @SERVICE_NAME_MAP[@service.downcase]
	    dest_dir_real = File.join(@dest_dir_base, "#{service_name}.#{@user_SN}", @partner_SN, "#{@partner_SN} (#{@adium_chat_time_start}).chatlog")
	    FileUtils.mkdir_p(dest_dir_real)
	    dest_file_path = dest_dir_real << '/' << "#{@partner_SN} (#{@adium_chat_time_start}).xml"
	    if File.exist?(dest_file_path)
		return Pidgin2Adium::Logs::FILE_EXISTS
	    end

	    all_msgs = ""
	    # TODO: inject?
	    @chat_lines.each { |obj| all_msgs << obj.get_output() }
	    # xml is done.
	    
	    # no \n before </chat> because all_msgs has it already
	    ret = sprintf('<?xml version="1.0" encoding="UTF-8" ?>'<<"\n"+
		      '<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="%s" service="%s">'<<"\n"<<'%s</chat>', @user_SN, service_name, all_msgs)

	    # we already checked to see if the file previously existed.
	    outfile = File.new(dest_file_path, 'w')
	    outfile.puts(ret)
	    outfile.close
	    return dest_file_path
	end
    end
end
