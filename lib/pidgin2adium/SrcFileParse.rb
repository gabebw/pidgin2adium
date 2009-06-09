# =SrcFileParse
# The class SrcFileParse has two subclasses, SrcTxtFileParse and SrcHtmlFileParse
# It parses the file passed into it and extracts the following
# from each line in the chat: time, alias, and message and/or status.

require 'rubygems'
require 'hpricot'
module Pidgin2Adium
    # The two subclasses of SrcFileParse,
    # SrcTxtFileParse and SrcHtmlFileParse, only differ
    # in that they have their own @line_regex, @line_regex_status,
    # and most importantly, createMsgData, which takes the
    # +MatchData+ objects from matching against @line_regex and
    # fits them into hashes.
    class SrcFileParse
	def initialize(srcPath, destDirBase, masterAlias, userTZ, userTZOffset)
	    @srcPath = srcPath
	    # these two are to pass to chatFG in parseFile
	    @destDirBase = destDirBase
	    @masterAlias = masterAlias
	    @userTZ = userTZ
	    @userTZOffset = userTZOffset
	    # Automagically does grouping for you. Will be inserted in @line_regex{,_status}
	    @timestamp_regex_str = '\(((?:\d{4}-\d{2}-\d{2} )?\d{1,2}:\d{1,2}:\d{1,2}(?: .{1,2})?)\)'
	    # the first line is special: it tells us
	    # 1) who we're talking to 
	    # 2) what time/date
	    # 3) what SN we used
	    # 4) what protocol (AIM, jabber...)
	    @first_line_regex = /Conversation with (.*?) at (.*?) on (.*?) \((.*?)\)/

	    # These maps are used in getAliasAndStatus
	    # Screen name is in regex group 1.
	    @status_map = {
		/(.+) logged in\.$/ => 'online',
		/(.+) logged out\.$/ => 'offline',
		/(.+) has signed on\.$/ => 'online',
		/(.+) has signed off\.$/ => 'offline',
		/(.+) has gone away\.$/ => 'away',
		/(.+) is no longer away\.$/ => 'available',
		/(.+) has become idle\.$/ => 'idle',
		/(.+) is no longer idle\.$/ => 'available',
		# file transfer
		/Starting transfer of .+ from (.+)/ => 'file-transfer-start',
		/^Offering to send .+ to (.+)$/ => 'fileTransferRequested',
		/(.+) is offering to send file/ => 'fileTransferRequested',
	    }

	    # statuses that come from my end. I totally made up these status names.
	    @my_status_map = {
		# encryption
		/^Received message encrypted with wrong key$/ => 'encrypt-error',
		/^Requesting key\.\.\.$/ => 'encrypt-error',
		/^Outgoing message lost\.$/ => 'encrypt-error',
		/^Conflicting Key Received!$/ => 'encrypt-error',
		/^Error in decryption- asking for resend\.\.\.$/ => 'encrypt-error',
		/^Making new key pair\.\.\.$/ => 'encrypt-key-create',
		# file transfer - these are in this (non-used) list because you can't get the alias out of matchData[1]
		/^You canceled the transfer of .+$/ => 'file-transfer-cancel',
		/^Transfer of file .+ complete$/ => 'fileTransferCompleted',
		# sending errors
		/^Last outgoing message not received properly- resetting$/ => 'sending-error',
		/^Resending\.\.\.$/ => 'sending-error',
		# connection errors
		/^Lost connection with the remote user:<br\/>Remote host closed connection\.$/ => 'lost-remote-conn',
		# direct IM stuff
		/^Attempting to connect to .+ at .+ for Direct IM\./ => 'direct-im-connect',
		/^Asking .+ to connect to us at .+ for Direct IM\./ => 'direct-im-ask',
		/^Direct IM with .+ failed/ => 'direct-im-failed',
		/^Attempting to connect to .+\.$/ => 'direct-im-connect',
		/^Attempting to connect via proxy server\.$/ => 'direct-im-proxy',
		/^Direct IM established$/ => 'direct-im-established',
		/^Lost connection with the remote user:<br\/>Windows socket error/ => 'direct-im-lost-conn',
		# chats
		/^.+ entered the room\.$/ => 'chat-entered-room',
		/^.+ left the room\.$/ => 'chat-left-room'
	    }

	end

	# Takes the body of a line of a chat and returns the [username, status] as a 2-element array.
	# Example:
	# Pass in "Generic Screenname228 has signed off" and it returns <tt>["Generic Screenname228", "offline"]</tt>
	def getAliasAndStatus(str)
	    alias_and_status = [nil, nil]

	    regex, status = @status_map.detect{ |regex, status| regex.match(str) }
	    if regex and status
		alias_and_status = [regex.match(str)[1], status]
	    else
		# not one of the regular statuses, try my statuses.
		regex, status = @my_status_map.detect{ |regex, status| regex.match(str) }
		alias_and_status = ['System Message', status]
	    end
	    return alias_and_status
	end

	def getTimeZoneOffset()
	    tz_regex = /([-+]\d+)[A-Z]{3}\.(txt|html?)/
	    tz_match = tz_regex.match(@srcPath)
	    tz_offset =  (tz_match.nil?) ? @userTZOffset : tz_match[1]
	    return tz_offset
	end

	# parseFile slurps up @srcPath into one big string and runs
	# SrcHtmlFileParse.cleanup if it's an HTML file.
	# It then uses regexes to break up the string, uses createMsgData
	# to turn the regex MatchData into data hashes, and feeds it to
	# ChatFileGenerator, which creates the XML data string.
	# This method returns a ChatFileGenerator object.
	def parseFile()
	    file = File.new(@srcPath, 'r')
	    # Deal with first line.
	    first_line_match = @first_line_regex.match(file.readline())
	    if first_line_match.nil?
		file.close()
		Pidgin2Adium.logMsg("Parsing of #{@srcPath} failed (could not find first line).", true)
		return false
	    else
		# one big string, without the first lien
		fileContent = File.read(@srcPath)
		file.close()
	    end
	    if self.class == SrcHtmlFileParse
		fileContent = self.cleanup(fileContent)
	    end

	    service = first_line_match[4]
	    # mySN is standardized to avoid "AIM.name" and "AIM.na me" folders
	    mySN = first_line_match[3].downcase.sub(' ', '')
	    otherPersonsSN = first_line_match[1]
	    chatTimePidgin_start = first_line_match[2]
	    chatFG = ChatFileGenerator.new(service,
					   mySN,
					   otherPersonsSN,
					   chatTimePidgin_start,
					   getTimeZoneOffset(),
					   @masterAlias,
					   @destDirBase)
	    all_line_matches = fileContent.scan( Regexp.union(@line_regex, @line_regex_status) )

	    # an empty chat window that got saved
	    if all_line_matches.empty?
		return chatFG
	    end

	    all_line_matches.each do |line|
		chatFG.appendLine( createMsgData(line) )
	    end
	    return chatFG
	end
    end

    class SrcTxtFileParse < SrcFileParse
	def initialize(srcPath, destDirBase, masterAlias, userTZ, userTZOffset)
	    super(srcPath, destDirBase, masterAlias, userTZ, userTZOffset)
	    # @line_regex matches a line in an HTML log file other than the first
	    # @line_regex matchdata:
	    # 0: timestamp
	    # 1: screen name
	    # 2: "<AUTO-REPLY>" or nil
	    # 3: message
	    @line_regex = /#{@timestamp_regex_str} (.*?) ?(<AUTO-REPLY>)?: (.*)$/
	    # @line_regex_status matches a status line
	    # @line_regex_status matchdata:
	    # 0: timestamp
	    # 1: message
	    @line_regex_status = /#{@timestamp_regex_str} ([^:]+?)[\r\n]{1,2}/
	end

	# createMsgData takes a +MatchData+ object (from @line_regex or @line_regex_status) and returns a hash
	# with the following keys: time, alias, and message and/or status.
	def createMsgData(matchObj)
	    msg_data_hash = { 'time' => nil, 'alias' => nil, 'status' => nil, 'body' => nil, 'auto-reply' => nil }
	    if matchObj[4..5] == [nil, nil]
		# regular message
		# ["10:58:29", "BuddyName", "<AUTO-REPLY>", "hello!\r", nil, nil]
		msg_data_hash['time'] = matchObj[0]
		msg_data_hash['alias'] = matchObj[1]
		msg_data_hash['auto-reply'] = (matchObj[2] != nil)
		# strip() to remove "\r" from end
		msg_data_hash['body'] = matchObj[3].strip
	    elsif matchObj[0..3] == [nil, nil, nil, nil]
		# status message
		# [nil, nil, nil, nil, "22:58:00", "BuddyName logged in."]
		alias_and_status = getAliasAndStatus(matchObj[5])
		msg_data_hash['time'] = matchObj[4]
		msg_data_hash['alias'] = alias_and_status[0]
		msg_data_hash['status'] = alias_and_status[1]
	    end
	    return msg_data_hash
	end
    end

    class SrcHtmlFileParse < SrcFileParse
	def initialize(srcPath, destDirBase, masterAlias, userTZ, userTZOffset)
	    super(srcPath, destDirBase, masterAlias, userTZ, userTZOffset)
	    # @line_regex matches a line in an HTML log file other than the first
	    # time matches on either "2008-11-17 14:12" or "14:12"
	    # @line_regex match obj:
	    # 0: timestamp, extended or not
	    # 1: alias
	    # 2: "&lt;AUTO-REPLY&gt;" or nil
	    # 3: message body
	    #  <span style='color: #000000;'>test sms</span>
	    @line_regex = /#{@timestamp_regex_str} ?<b>(.*?) ?(&lt;AUTO-REPLY&gt;)?:?<\/b> ?(.*)<br ?\/>/ #(?:[\n\r]{1,2}<(?:font|\/body))/s
	    # @line_regex_status matches a status line
	    # @line_regex_status match obj:
	    # 0: timestamp
	    # 1: status message
	    @line_regex_status = /#{@timestamp_regex_str} ?<b> (.*?)<\/b><br\/>/
	end

	# createMsgData takes a +MatchData+ object (from @line_regex or @line_regex_status) and returns a hash
	# with the following keys: time, alias, and message and/or status.
	def createMsgData(matchObj)
	    msg_data_hash = { 'time' => nil,
		'alias' => nil,
		'auto-reply' => nil,
		'body' => nil,
		'status' => nil}
	    # the Regexp.union leaves nil where one of the regexes didn't match.
	    # (Is there any way to have it not do this?)
	    # ie
	    # the first one matches: ['foo', 'bar', 'baz', 'bash', nil, nil]
	    # second one matches: [nil, nil, nil, nil, 'bim', 'bam']
	    if matchObj[0..3] == [nil, nil, nil, nil]
		# This is a status message.
		# slice off results from other Regexp
		# becomes: ["11:27:53", "Generic Screenname228 logged in."]
		matchObj = matchObj[4..5]
		alias_and_status = getAliasAndStatus(matchObj[1])
		msg_data_hash['time'] = matchObj[0]
		msg_data_hash['alias'] = alias_and_status[0]
		msg_data_hash['status'] = alias_and_status[1]
	    elsif matchObj[4..5] == [nil, nil]
		# Either a regular message line or an auto-reply/away message.
		# slice off results from other Regexp
		matchObj = matchObj[0..3]
		msg_data_hash['time'] = matchObj[0]
		msg_data_hash['alias'] = matchObj[1]
		msg_data_hash['body'] = matchObj[3]
		if not matchObj[2].nil?
		    # an auto-reply message
		    msg_data_hash['auto-reply'] = true
		end
	    end
	    return msg_data_hash
	end

	# Removes <font> tags, empty <a>s, spans with either no color
	# information or color information that just turns the text black.
	# Returns a string.
	def cleanup(text)
	    color_regex = /.*(color: ?#[[:alnum:]]{6}; ?).*/
	    # For some reason, Hpricot doesn't work well with
	    # elem.swap(elem.innerHTML) when the elements are nested
	    # (eg doc.search('font') only returns the outside <font> tags,
	    # not "font font") and also it appears that it doesn't reinterpret
	    # the doc when outside tags are swapped with their innerHTML (so
	    # when <html> tags are replaced with their innerHTML, then
	    # a search for <font> tags in the new HTML fails).
	    # Long story short, we use gsub.
	    text.gsub!(/<\/?(html|body|font).*?>/, '')
	    doc = Hpricot(text)
	    # These empty links sometimes are appended to every line in a chat,
	    # for some weird reason. Remove them.
	    doc.search("a[text()='']").remove
	    spans = doc.search('span')
	    spans.each do |span|
		if span.empty?
		    Hpricot::Elements[span].remove
		else
		    # No need to check for the span.attributes.key?('style')
		    if span[:style] =~ color_regex
			# Remove black-text spans after other processing because
			# the processing can reduce spans to that
			# Yes, sometimes there's a ">" before the ";"
			span[:style] = span[:style].gsub(color_regex, '\1').
					    gsub(/color: ?#000000>?; ?/,'')
			# Remove span but keep its contents
			span.swap(span.innerHTML) if span[:style].strip() == ''
		    else
			span.swap(span.innerHTML)
		    end
		end
	    end
	    return doc.to_html
	end
    end
end # end module
