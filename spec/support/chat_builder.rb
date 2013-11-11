# Usage:
# # determine format sender passed-in file
# ChatBuilder.new('file.html') do |b|
#   b.first_line
#   b.message sender_screen_name: 'screenname', sender_alias: 'Gabe B-W',
#          time: '2010-01-30', text: 'blarg balrg'
#   b.message 'blerg' sender_screen_name: 'name2',
#     sender_alias: 'another name', time: '2010-01-30'
#   b.away_message
#   b.status_message
# end

class ChatBuilder
  DEFAULT_THEIR_SCREEN_NAME = 'default_sender_sn'

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
