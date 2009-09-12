#!/usr/bin/ruby

# Author: Gabe Berke-Williams 2008-11-25
# Requires rubygems and hpricot (http://wiki.github.com/why/hpricot)

# Script to import pidgin logs into Adium. It uses Applescript to create new statuses in Adium.
# Stupid binary status file format. Thanks a lot, Adium.
# It doesn't work in Mac OSX 10.5 (Leopard).
# See: http://trac.adiumx.com/ticket/8863
# It should work in Mac OSX 10.4 (Tiger), but is untested.
#
# TODO: check adium version in
# /Applications/Adium.app/Contents
# with this:
#         <key>CFBundleShortVersionString</key>
#         <string>1.3.4</string>
# For Mac 10.5+, needs to be 1.4; should work for 10.4 with 1.3.x

require 'rubygems'
require 'hpricot'

module Pidgin2Adium
    class Status
	def initialize(xml_file)
	    @xml_file = File.expand_path(xml_file)
	    #xml_file=File.expand_path("~/Desktop/purple/status.xml")
	    # Unescape for Adium.
	    @TRANSLATIONS = {
		'&amp;' => '&',
		'&lt;' => '<',
		'&gt;' => '>',
		# escape quotes for shell quoting in tell -e 'blah' below
		'&quot;' => '\"',
		'&apos;' => "\\'",
		"<br>" => "\n"
	    }
	end
	
	def start
	    # For some reason Hpricot doesn't like entities in attributes,
	    # but since that only affects the status name, which only we see,
	    # that's not really a problem.
	    doc = Hpricot( File.read(xml_file) )
	    $max_id = get_max_status_id
	    # remove <substatus>'s because sometimes their message is different
	    # from the actual message, and we don't want to grab them accidentally
	    doc.search('substatus').remove

	    doc.search('status').each do |status|
		next if status.search('message').empty?
		add_status_to_adium(status)
	    end

	    puts "All statuses have been migrated. Enjoy!"
	end


	def unescape(str)
	    unescaped_str = str.clone
	    # Unescape the escaped entities in Pidgin's XML.
	    # translate "&amp;" first because sometimes the entities are
	    # like "&amp;gt;"
	    unescaped_str.gsub!('&amp;', '&')
	    TRANSLATIONS.each do |k,v|
		unescaped_str.gsub!(k, v)
	    end
	    return unescaped_str
	end

	def get_max_status_id
	    # osascript line returns like so: "-1000, -8000, -1001, 24, -1002\n"
	    # Turn the single String into an array of Fixnums.
	    script = `osascript -e 'tell application "Adium" to get id of every status'`
	    id = script.split(',').map{ |x| x.to_i }.max
	    return id
	end

	def add_status_to_adium(elem)
	    # pass in <status> element
	    id = ($max_id += 1)
	    # status_type is invisible/available/away
	    status_type = elem.search('state').inner_html
	    title = unescape( elem[:name] )
	    status_message = unescape( elem.search(:message).inner_html )
	    puts '-' * 80
	    puts "status_type: #{status_type}"
	    puts "title: #{title}"
	    puts "status_message: #{status_message}"
	    puts '-' * 80
	    # TODO: when it actually works, remove this line
	    command="osascript -e 'tell application \"Adium\" to set myStat to (make new status with properties {id:#{id}, saved:true, status type:#{status_type}, title:\"#{title}\", message:\"#{status_message}\", autoreply:\"#{status_message}\"})'"
	    # TODO: popen[123]?
	    p `#{command}`
	    if $? != 0
		puts "*" * 80
		puts "command: #{command}"
		puts "Uh-oh. Something went wrong."
		puts "The command that failed is above."
		# given 10.x.y, to_f leaves off y
		if `sw_vers -productVersion`.to_f == 10.5
		    puts "You are running Mac OS X 10.5 (Leopard)."
		    puts "This script does not work for that version."
		    puts "It should work for Mac OS X 10.4 (Tiger),"
		    puts "but is untested."
		    puts "See: http://trac.adiumx.com/ticket/8863"
		end
		puts "Return status: #{$?}"
		puts "Error, exiting."
		raise "You need Mac OS X Tiger (10.4)"
	    end
	end
    end
end
