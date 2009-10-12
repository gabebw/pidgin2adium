module Pidgin2Adium
    #From Wordpress's formatting.php; rewritten in Ruby by Gabe Berke-Williams, 2009.
    #Balances tags of string using a modified stack.
    #
    # @author Leonard Lin <leonard@acm.org>
    # @license GPL v2.0
    # @copyright November 4, 2001
    # @return string Balanced text.
    def balance_tags( text )
	tagstack = []
	stacksize = 0
	tagqueue = ''
	newtext = ''
	single_tags = %w{br hr img input meta} # Known single-entity/self-closing tags
	nestable_tags = %w{blockquote div span} # Tags that can be immediately nested within themselves
	tag_regex = /<(\/?\w*)\s*([^>]*)>/

	# WP bug fix for comments - in case you REALLY meant to type '< !--'
	text.gsub!('< !--', '<    !--')

	# WP bug fix for LOVE <3 (and other situations with '<' before a number)
	text.gsub!(/<([0-9]{1})/, '&lt;\1')

	while ( regex = text.match(tag_regex) )
	    regex = regex.to_a
	    newtext << tagqueue
	    i = text.index(regex[0])
	    l = regex[0].length

	    # clear the shifter
	    tagqueue = ''
	    # Pop or Push
	    if (regex[1][0,1] == "/") # End Tag
		tag = regex[1][1,regex[1].length].downcase
		# if too many closing tags
		if(stacksize <= 0)
		    tag = ''
		    #or close to be safe tag = '/' . tag
		    # if stacktop value = tag close value then pop
		elsif (tagstack[stacksize - 1] == tag) # found closing tag
		    tag = '</' << tag << '>'; # Close Tag
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
		tag = regex[1].downcase

		# Tag Cleaning
		if( (regex[2].slice(-1,1) == '/') || (tag == '') )
		    # If: self-closing or '', don't do anything.
		elsif ( single_tags.include?(tag) )
		    # ElseIf: it's a known single-entity tag but it doesn't close itself, do so
		    regex[2] << '/'
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
		attributes = regex[2]
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
	    newtext << text[0,i] << tag
	    text = text[i+l, text.length - (i+l)]
	end

	# Clear Tag Queue
	newtext << tagqueue

	# Add Remaining text
	newtext << text

	# Empty Stack
	while(x = tagstack.pop)
	    newtext << '</' << x << '>'; # Add remaining tags to close
	end

	# WP fix for the bug with HTML comments
	newtext.gsub!("< !--", "<!--")
	newtext.gsub!("<    !--", "< !--")

	return newtext
    end
end
