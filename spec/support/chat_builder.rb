# Usage:
# # determine format from passed-in file
# ChatBuilder.new('file.html') do |b|
#   b.first_line
#   b.message from: 'name1', from_alias: 'Gabe B-W',
#          time: '2010-01-30', text: 'blarg balrg'
#   b.message 'blerg' from: 'name2',
#     from_alias: 'another name', time: '2010-01-30'
#   b.away_message
#   b.status_message
# end

class ChatBuilder
  DEFAULT_FROM = 'FROM_SN'

  def initialize(file)
    @file = file
    @first_line = nil
    @messages = []
  end

  def write(separator = "")
    @file.puts(first_line)
    @messages.each do |message|
      @file.puts(message + separator)
    end
    @file.close
  end
end
