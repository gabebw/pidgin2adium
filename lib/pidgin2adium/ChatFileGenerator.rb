# ADD DOCUMENTATION
require 'pidgin2adium/balance-tags.rb'

module Pidgin2Adium
    class ChatFileGenerator
	def initialize(service, userSN, partnerSN, adiumChatTimeStart, destDirBase)
	    @service = service
	    @userSN = userSN
	    @partnerSN = partnerSN
	    @adiumChatTimeStart = adiumChatTimeStart
	    @destDirBase = destDirBase

	    # @chatLines is an array of Message, Status, and Event objects
	    @chatLines = []
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

	# Add a line to @chatLines.
	# It is its own method because attr_writer creates the method
	# 'chatMessage=', which doesn't help for chatMessage.push
	def appendLine(line)
	    @chatLines.push(line)
	end

	# Returns path of output file
	def convert()
	    serviceName = @SERVICE_NAME_MAP[@service.downcase]
	    destDirReal = File.join(@destDirBase, "#{serviceName}.#{@userSN}", @partnerSN, "#{@partnerSN} (#{@adiumChatTimeStart}).chatlog")
	    FileUtils.mkdir_p(destDirReal)
	    destFilePath = destDirReal << '/' << "#{@partnerSN} (#{@adiumChatTimeStart}).xml"
	    if File.exist?(destFilePath)
		return Pidgin2Adium::Logs::FILE_EXISTS
	    end

	    allMsgs = ""
	    # TODO: inject?
	    @chatLines.each { |obj| allMsgs << obj.getOutput() }
	    # xml is done.
	    
	    # no \n before </chat> because allMsgs has it already
	    ret = sprintf('<?xml version="1.0" encoding="UTF-8" ?>'<<"\n"+
		      '<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="%s" service="%s">'<<"\n"<<'%s</chat>', @userSN, serviceName, allMsgs)

	    # we already checked to see if the file previously existed.
	    outfile = File.new(destFilePath, 'w')
	    outfile.puts(ret)
	    outfile.close
	    return destFilePath
	end
    end
end
