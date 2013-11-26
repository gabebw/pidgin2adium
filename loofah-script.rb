#!/usr/bin/env ruby

require 'loofah'

html = '<font><a HREF="http://software.johnroark.net/">http://software.johnroark.net/</a></font>'

# Remove tags that aren't on the whitelist, leaving their contents behind
class StripUnsafeTags < Loofah::Scrubber
  def initialize(safe_tags)
    @safe_tags = safe_tags
    @direction = :bottom_up
  end

  def scrub(node)
    unless @safe_tags.include?(node.name)
      node.before node.children
      node.remove
    end
  end
end

puts Loofah.scrub_fragment(html, StripUnsafeTags.new(%w(a)))
