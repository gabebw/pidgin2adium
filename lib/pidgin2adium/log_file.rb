require 'fileutils'

module Pidgin2Adium
  # A holding object for the result of LogParser.parse.  It makes the
  # instance variable @chat_lines available, which is an array of Message
  # subclass instances (XMLMessage, Event, etc.)
  # Here is a list of the instance variables for each class in @chat_lines:
  #
  # <b>All of these variables are read/write.</b>
  # All::		 sender, time, buddy_alias
  # XMLMessage::	 body
  # AutoReplyMessage:: body
  # Event::		 body, event_type
  # StatusMessage::	 status
  class LogFile
    include Enumerable

    def initialize(chat_lines, service, user_SN, partner_SN, adium_chat_time_start)
      @chat_lines = chat_lines
      @user_SN = user_SN
      @partner_SN = partner_SN
      @adium_chat_time_start = adium_chat_time_start
      @service = service_name_map[service.downcase]
    end

    attr_reader :chat_lines

    # Returns contents of log file
    def to_s
      @chat_lines.map(&:to_s).join
    end

    def each(&block)
      @chat_lines.each(&block)
    end

    # Returns one of:
    # * false (if an error occurred),
    # * Pidgin2Adium::FILE_EXISTS if the file to be generated already exists, or
    # * the path to the new Adium log file.
    def write_out(output_dir_base = ADIUM_LOG_DIR)
      # output_dir_base + "/buddyname (2009-08-04T18.38.50-0700).chatlog"
      output_dir = File.join(output_dir_base, "#{@service}.#{@user_SN}", @partner_SN, "#{@partner_SN} (#{@adium_chat_time_start}).chatlog")
      # output_dir + "/buddyname (2009-08-04T18.38.50-0700).chatlog/buddyname (2009-08-04T18.38.50-0700).xml"
      output_path = output_dir + '/' + "#{@partner_SN} (#{@adium_chat_time_start}).xml"

      begin
        FileUtils.mkdir_p(output_dir)
      rescue => bang
        Pidgin2Adium.error "Could not create destination directory for log file. (Details: #{bang.class}: #{bang.message})"
        return false
      end
      if File.exist?(output_path)
        return FILE_EXISTS
      end

      begin
        open(output_path, 'w') do |f|
          f.print(chat_string)
        end
      rescue => bang
        Pidgin2Adium.error "Could not open log file for writing. (Details: #{bang.class}: #{bang.message})"
        return false
      end

      output_path
    end

    private

    def chat_string
      # no \n before </chat> because to_s has it already
      %(<?xml version="1.0" encoding="UTF-8" ?>\n) +
        %(<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="#{@user_SN}" service="#{@service}">\n#{to_s}</chat>)
    end

    def service_name_map
      # key is for Pidgin, value is for Adium
      # Just used for <service>.<screenname> in directory structure
      { 'aim' => 'AIM',
        'jabber' =>'Jabber',
        'gtalk'=> 'GTalk',
        'icq' => 'ICQ',
        'qq' => 'QQ',
        'msn' => 'MSN',
        'yahoo' => 'Yahoo!'}
    end
  end
end
