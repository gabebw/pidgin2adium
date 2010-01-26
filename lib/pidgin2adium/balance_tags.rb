module Pidgin2Adium
    # Balances tags of string using a modified stack. Returns a balanced
    # string, but also affects the text passed into it!
    # Use text = balance_tags(text).
    
    # From Wordpress's formatting.php; rewritten in Ruby by Gabe
    # Berke-Williams, 2009.
    # Author:: Leonard Lin <leonard@acm.org>
    # License:: GPL v2.0
    # Copyright:: November 4, 2001
    def Pidgin2Adium.balance_tags( text )
	tagstack = []
	stacksize = 0
	tagqueue = ''
	newtext = ''
	single_tags = %w{br hr img input meta} # Known single-entity/self-closing tags
	#nestable_tags = %w{blockquote div span} # Tags that can be immediately nested within themselves
	nestable_tags = %w{blockquote div span font} # Tags that can be immediately nested within themselves
	# 1: tagname, with possible leading "/"
	# 2: attributes
	tag_regex = /<(\/?\w*)\s*([^>]*)>/

	# WP bug fix for comments - in case you REALLY meant to type '< !--'
	text.gsub!('< !--', '<    !--')

	# WP bug fix for LOVE <3 (and other situations with '<' before a number)
	text.gsub!(/<([0-9]{1})/, '&lt;\1')

	while ( pos = (text =~ tag_regex) )
	    newtext << tagqueue
	    tag = $1.downcase
	    attributes = $2
	    matchlen = $~[0].size

	    # clear the shifter
	    tagqueue = ''
	    # Pop or Push
	    if (tag[0,1] == "/") # End Tag
		tag.slice!(0,1)
		# if too many closing tags
		if(stacksize <= 0)
		    tag = ''
		    #or close to be safe: tag = '/' << tag
		elsif (tagstack[stacksize - 1] == tag) # found closing tag
		    # if stacktop value == tag close value then pop
		    tag = '</' << tag << '>' # Close Tag
		    # Pop
		    tagstack.pop
		    stacksize -= 1
		else # closing tag not at top, search for it
		    (stacksize-1).downto(0) do |j|
			if (tagstack[j] == tag)
			    # add tag to tagqueue
			    ss = stacksize - 1
			    ss.downto(j) do |k|
				tagqueue << '</' << tagstack.pop << '>'
				stacksize -= 1
			    end
			    break
			end
		    end
		    tag = ''
		end
	    else
		# Begin Tag

		# Tag Cleaning
		if( (attributes[-1,1] == '/') || (tag == '') )
		    # If: self-closing or '', don't do anything.
		elsif ( single_tags.include?(tag) )
		    # ElseIf: it's a known single-entity tag but it doesn't close itself, do so
		    attributes << '/'
		else
		    # Push the tag onto the stack
		    # If the top of the stack is the same as the tag we want to push, close previous tag
		    if ((stacksize > 0) &&
			! nestable_tags.include?(tag) &&
			(tagstack[stacksize - 1] == tag))
			tagqueue = '</' << tagstack.pop << '>'
			stacksize -= 1
		    end
		    tagstack.push(tag)
		    stacksize += 1
		end

		# Attributes
		if(attributes != '')
		    attributes = ' ' << attributes
		end
		tag = '<' << tag << attributes << '>'
		#If already queuing a close tag, then put this tag on, too
		if (tagqueue)
		    tagqueue << tag
		    tag = ''
		end
	    end
	    newtext << text[0,pos] << tag
	    text = text[pos+matchlen, text.length - (pos+matchlen)]
	end

	# Clear Tag Queue
	newtext << tagqueue

	# Add Remaining text
	newtext << text

	# Empty Stack
	tagstack.reverse_each do |t|
	    newtext << '</' << t << '>' # Add remaining tags to close
	end

	# WP fix for the bug with HTML comments
	newtext.gsub!("< !--", "<!--")
	newtext.gsub!("<    !--", "< !--")

	return newtext
    end
end
