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

    attr_reader :chat_lines, :service, :user_SN, :partner_SN, :adium_chat_time_start

    # Returns contents of log file
    def to_s
      @chat_lines.map(&:to_s).join
    end

    def each(&block)
      @chat_lines.each(&block)
    end

    # Set overwrite=true to create a logfile even if logfile already exists.
    # Returns one of:
    # * false (if an error occurred),
    # * Pidgin2Adium::FILE_EXISTS if the file to be generated already exists and overwrite=false, or
    # * the path to the new Adium log file.
    def write_out(overwrite = false, output_dir_base = ADIUM_LOG_DIR)
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
      if overwrite
        unless File.exist?(output_path)
          # File doesn't exist, but maybe it does with a different
          # time zone. Check for a file that differs only in time
          # zone and, if found, change @output_path to target it.
          maybe_matches = Dir.glob(output_dir_base + '/' << File.basename(output_path).sub(/-\d{4}\)\.chatlog$/, '') << '/*')
          unless maybe_matches.empty?
            output_path = maybe_matches[0]
          end
        end
      else
        if File.exist?(output_path)
          return FILE_EXISTS
        end
      end

      begin
        outfile = File.new(output_path, 'w')
      rescue => bang
        Pidgin2Adium.error "Could not open log file for writing. (Details: #{bang.class}: #{bang.message})"
        return false
      end

      # no \n before </chat> because to_s has it already
      outfile.printf('<?xml version="1.0" encoding="UTF-8" ?>'<<"\n"+
                     '<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="%s" service="%s">'<<"\n"<<'%s</chat>',
                     @user_SN, @service, to_s)
      outfile.close

      return output_path
    end

    private

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
