# ADD DOCUMENTATION
require 'pidgin2adium/balance-tags.rb'
require 'hpricot'

module Pidgin2Adium
    def Pidgin2Adium.normalizeBodyEntities!(body)
	# Convert '&' to '&amp;' only if it's not followed by an entity.
	body.gsub!(/&(?!lt|gt|amp|quot|apos)/, '&amp;')
	# replace single quotes with '&apos;' but only outside <span>s.
	parts = body.split(/(<\/?span.*?>)/)
	body = parts.map{ |part| part.match(/<\/?span/) ? part : part.gsub("'", '&apos;') }.join('')
    end
    
    def Pidgin2Adium.normalizeBody!(body, aliasStr)
	# Fix mismatched tags.
	body = Pidgin2Adium.balance_tags(body)
	normalizeBodyEntities!(body)
	if aliasStr[0,3] == '***'
	    # "***<alias>" is what pidgin sets as the alias for a /me action
	    aliasStr.slice!(0,3)
	    body = '*' + body + '*'
	end
	body = '<div><span style="font-family: Helvetica; font-size: 12pt;">' +
		body +
		'</span></div>'
    end

    class ChatFileGenerator
	def initialize(service, mySN, otherPersonsSN, chatTimePidgin_start, tzOffset, masterAlias, destDirBase)
	    # basicTimeInfo is for files that only have the full timestamp at
	    # the top; we can use it to fill in the minimal per-line timestamps.
	    # It has only 3 elements ([year, month, dayofmonth]) because
	    # you should be able to fill everything else in.
	    # If you can't, something's wrong.
	    @basicTimeInfo = nil
	    # @chatMessage is a 2D array composed of arrays like so (e.g.):
	    # ['time'=>'2:23:48 PM', 'alias'=>'Me', 'status' => 'available', 'body'=>'abcdefg', auto-reply=true]
	    @chatMessage=[]
	    # chatTimeAdium_start format: YYYY-MM-DD\THH.MM.SS[+-]TZ_HRS like so:
	    # 2008-10-05T22.26.20-0800
	    @chatTimeAdium_start=nil
	    @chatTimePidgin_start=chatTimePidgin_start
	    @destDirBase=destDirBase
	    @masterAlias=masterAlias
	    @mySN=mySN
	    @otherPersonsSN=otherPersonsSN
	    @service=service
	    @tzOffset=tzOffset
	    # key is for Pidgin, value is for Adium
	    # Just used for <service>.<screenname> in directory structure
	    @SERVICE_NAME_MAP={'aim'=>'AIM',
		'jabber'=>'jabber',
		'gtalk'=>'GTalk',
		'icq' => 'ICQ',
		'qq'=>'QQ',
		'msn'=>'MSN',
		'yahoo'=>'Yahoo'}
	end

	def convert()
	    initChatTime()
	    return buildDomAndOutput()
	end

	def initChatTime()
	    #  ParseDate.parsedate "Tuesday, July 5th, 2007, 18:35:20 UTC"
	    #  # => [2007, 7, 5, 18, 35, 20, "UTC", 2]
	    # [year, month, day of month, hour, minute, sec, timezone, day of week] 
	    # strtotime returns seconds since the epoch
	    @chatTimeAdium_start = createAdiumDate(@chatTimePidgin_start)
	    @basicTimeInfo = ParseDate.parsedate(@chatTimePidgin_start)[0..2]
	end

	# Add a line to @chatMessage.
	# It is its own method because attr_writer creates the method 'chatMessage=', which doesn't help for chatMessage.push
	def appendLine(line)
	    @chatMessage.push(line)
	end

	# 
	def createAdiumDate(date)
	    epochSecs = getEpochSeconds(date)
	    if @tzOffset.nil?
		Pidgin2Adium.logMsg("@tzOffset is nil. This really shouldn't happen.", true)
		@tzOffset = "+0"
	    end
	    return Time.at(epochSecs).strftime("%Y-%m-%dT%H.%M.%S#{@tzOffset}")
	end

	def getEpochSeconds(timestr)
	    parsed_date = ParseDate.parsedate(timestr)
	    [0, 1, 2].each do |i|
		parsed_date[i] = @basicTimeInfo[i] if parsed_date[i].nil?
	    end
	    return Time.local(*parsed_date).tv_sec
	end

	def getScreenNameByAlias(aliasStr)
	    myAliasStr = aliasStr.clone
	    myAliasStr.slice!(0,3) if myAliasStr[0,3] == '***'
	    if aliasStr==""
		return ""
	    else
		return @masterAlias.include?(myAliasStr.downcase.gsub(/\s*/, '')) ? @mySN : @otherPersonsSN
	    end
	end

	# returns path of output file
	def buildDomAndOutput()
	    serviceName = @SERVICE_NAME_MAP[@service.downcase]
	    destDirReal = File.join(@destDirBase, "#{serviceName}.#{@mySN}", @otherPersonsSN, "#{@otherPersonsSN} (#{@chatTimeAdium_start}).chatlog")
	    FileUtils.mkdir_p(destDirReal)
	    destFilePath = destDirReal + '/' + "#{@otherPersonsSN} (#{@chatTimeAdium_start}).xml"
	    if File.exist?(destFilePath)
		return Pidgin2Adium::Logs::FILE_EXISTS
	    end

	    # no \n before </chat> because {body} has it already
	    chatLogTemplate = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
		"<chat xmlns=\"http://purl.org/net/ulf/ns/0.4-02\" account=\"#{@mySN}\" service=\"#{serviceName}\">\n{body}</chat>"

	    allMsgs = ""
	    @chatMessage.each do |msg|
		# template is set to a copy of one of the three templates, 
		# the {...} vars are subbed, and then it's added to allMsgs
		template = nil
		# Note:
		# away/auto message has both body and status set
		# pure status has status but not body set
		# pure message has body set but not status
		begin
		    chatTimeAdium = createAdiumDate(msg['time'])
		rescue TypeError => bang
		    puts '*' * 80
		    @chatMessage.each { |m| p m }
		    puts "Oops! Time error! on msg:"
		    p msg
		    puts "Rest of message is above, just below the stars."
		    return false
		end
		sender = getScreenNameByAlias(msg['alias'])
		time = chatTimeAdium
		aliasStr = msg['alias']
		if msg['body']
		    body = msg['body']
		    if msg['status'].nil?
			# Body with no status
			if msg['auto-reply'] == true
			    # auto-reply from away message
			    template = AutoReplyMessage.new(sender, time, aliasStr, body)
			else
			    # pure regular message
			    template = XMLMessage.new(sender, time, aliasStr, body)
			end
		    else 
			# Body with status message
			template = AwayMessage.new(sender, time, aliasStr, body)
		    end
		elsif msg['status']
		    # Status message, no body
		    template = StatusMessage.new(sender, time, aliasStr, msg['status'])
		else
		    Pidgin2Adium.logMsg("msg has neither status nor body key set. Unsure what to do. msg is as follows:", true)
		    Pidgin2Adium.logMsg(sprintf('%p', msg), true)
		    return false
		end
		begin
		    allMsgs += template.getOutput()
		rescue TypeError => bang
		    Pidgin2Adium.logMsg "TypeError: #{bang.message}"
		    Pidgin2Adium.logMsg "This is probably caused by an unrecognized status string."
		    Pidgin2Adium.logMsg "Go to the file currently being worked on (displayed above) at time #{msg['time']}"
		    Pidgin2Adium.logMsg "and add the status message there to one of the hashes in SrcHtmlFileParse.getAliasAndStatus."
		    Pidgin2Adium.logMsg "**Debug info**"
		    Pidgin2Adium.logMsg "msg: #{msg.inspect}"
		    Pidgin2Adium.logMsg "--"
		    Pidgin2Adium.logMsg "Exiting."
		    return false
		end
	    end
	    ret = chatLogTemplate.sub("{body}", allMsgs)
	    # xml is ok.

	    # we already checked to see if the file previously existed.
	    outfile = File.new(destFilePath, 'w')
	    outfile.puts(ret)
	    outfile.close
	    return destFilePath
	end

	# A holding object for each line of the chat.
	# It is subclassed as appropriate (eg AutoReplyMessage).
	# All Messages have senders, times, and aliases.
	class Message
	    def initialize(sender, time, aliasStr)
		@sender = sender
		@time = time
		@aliasStr = aliasStr
	    end
	end

	# Basic message with body text (as opposed to pure status messages which have no body).
	class XMLMessage < Message
	    def initialize(sender, time, aliasStr, body)
		super(sender, time, aliasStr)
		@body = Pidgin2Adium.normalizeBody!(body, @aliasStr)
	    end

	    def getOutput
		return sprintf('<message sender="%s" time="%s" alias="%s">%s</message>' + "\n",
			       @sender, @time, @aliasStr, @body)
	    end

	end

	# An auto reply message, meaning it has a body.
	class AutoReplyMessage < XMLMessage
	    def getOutput
		return sprintf('<message sender="%s" time="%s" alias="%s" auto="true">%s</message>' + "\n",
			       @sender, @time, @aliasStr, @body)
	    end
	end

	class AwayMessage < XMLMessage
	    def getOutput
		return sprintf('<status type="away" sender="%s" time="%s" alias="%s">%s</status>' + "\n",
			       @sender, @time, @aliasStr, @body)
	    end
	end

	# A message saying e.g. "Blahblah has gone away."
	class StatusMessage < Message
	    def initialize(sender, time, aliasStr, status)
		super(sender, time, aliasStr)
		@status = status
	    end
	    def getOutput
		return sprintf('<status type="%s" sender="%s" time="%s" alias="%s"/>' + "\n",
			       @status, @sender, @time, @aliasStr)
	    end
	end
    end
end
