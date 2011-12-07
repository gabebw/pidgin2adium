module Pidgin2Adium
  # Balances tags of string using a modified stack. Returns a balanced
  # string, but also affects the text passed into it!
  # Use text = balance_tags(text).

  # From Wordpress's formatting.php; rewritten in Ruby by Gabe
  # Berke-Williams, 2009.
  # Author:: Leonard Lin <leonard@acm.org>
  # License:: GPL v2.0
  # Copyright:: November 4, 2001
  class TagBalancer
    def initialize(text)
      @text = text

      @tagstack  = []
      @stacksize = 0
      @tagqueue  = ''

      # Known single-entity/self-closing tags
      @self_closing_tags = %w(br hr img input meta)

      # Tags that can be immediately nested within themselves
      @nestable_tags = %w(blockquote div span font)

      # 1: tagname, with possible leading "/"
      # 2: attributes
      @tag_regex = /<(\/?\w*)\s*([^>]*)>/
    end

    def balance
      text    = @text.dup
      newtext = ''

      @tagstack  = []
      @stacksize = 0
      @tagqueue  = ''

      # WP bug fix for comments - in case you REALLY meant to type '< !--'
      text.gsub!('< !--', '<    !--')

      # WP bug fix for LOVE <3 (and other situations with '<' before a number)
      text.gsub!(/<([0-9]{1})/, '&lt;\1')

      while ( pos = (text =~ @tag_regex) )
        newtext << @tagqueue
        tag        = $1.downcase
        attributes = $2
        matchlen   = $~[0].size

        # clear the shifter
        @tagqueue = ''
        # Pop or Push
        if end_tag?(tag)
          tag.slice!(0,1)
          if too_many_closing_tags?
            tag = ''
            #or close to be safe: tag = '/' << tag
          elsif closing_tag?(tag)
            # if stacktop value == tag close value then pop
            tag = "</#{tag}>" # Close Tag
            @tagstack.pop
            @stacksize -= 1
          else
            # closing tag not at top, search for it
            (@stacksize-1).downto(0) do |j|
              if @tagstack[j] == tag
                # add tag to tagqueue
                ss = @stacksize - 1
                ss.downto(j) do |k|
                  @tagqueue << "</#{@tagstack.pop}>"
                  @stacksize -= 1
                end

                break
              end
            end
            tag = ''
          end
        else
          # Begin Tag

          # Tag Cleaning
          if self_closing?(attributes) || empty_tag?(tag)
          elsif self_closing?(tag)
            # ElseIf: it's a known single-entity tag but it doesn't close itself, do so
            attributes << '/'
          else
            # Push the tag onto the stack
            # If the top of the stack is the same as the tag we want to push, close previous tag
            if (@stacksize > 0 &&
                ! nestable?(tag) &&
                @tagstack[@stacksize - 1] == tag)
              @tagqueue = "</#{@tagstack.pop}>"
              @stacksize -= 1
            end
            @tagstack.push(tag)
            @stacksize += 1
          end

          # Attributes
          if attributes != ''
            attributes = ' ' + attributes
          end
          tag = "<#{tag}#{attributes}>"
          #If already queuing a close tag, then put this tag on, too
          if @tagqueue
            @tagqueue << tag
            tag = ''
          end
        end
        newtext << text[0,pos] << tag
        text = text[pos+matchlen, text.length - (pos+matchlen)]
      end

      # Clear Tag Queue
      newtext << @tagqueue

      # Add Remaining text
      newtext << text

      # Empty Stack
      @tagstack.reverse_each do |t|
        newtext << "</#{t}>" # Add remaining tags to close
      end

      # WP fix for the bug with HTML comments
      newtext.gsub!("< !--", "<!--")
      newtext.gsub!("<    !--", "< !--")

      newtext
    end

    private

    def end_tag?(string)
      string[0,1] == "/"
    end

    def closing_tag?(tag)
      @tagstack[@stacksize - 1] == tag
    end

    def too_many_closing_tags?
      @stacksize <= 0
    end

    def self_closing?(attributes)
      attributes[-1,1] == '/'
    end

    def empty_tag?(tag)
      tag == ''
    end

    def self_closing?(tag)
      @self_closing_tags.include?(tag)
    end

    def nestable?(tag)
      @nestable_tags.include?(tag)
    end
  end
end
