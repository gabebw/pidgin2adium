require 'fileutils'

# Pidgin2Adium.oops and Pidgin2Adium.warn both use warn() to output errors.
# Setting $-w (the warning level) to nil suppresses them, which makes for
# much prettier test output.
$-w=nil # OMGHAX

$LOAD_PATH.unshift(File.expand_path('..',  __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'pidgin2adium'
require 'time'
require 'bourne'

Dir['spec/support/**/*.rb'].each do |f|
  require File.expand_path(f)
end

RSpec.configure do |config|
  config.mock_with :mocha
  config.before(:all) do
    @current_dir = File.dirname(__FILE__)
    @aliases = %w{gabebw gabeb-w gbw me}.join(',')
    # -7 => "-0700"
    @current_tz_offset = sprintf("%+03d00", Time.zone_offset(Time.new.zone) / 3600)

    @logfile_path = File.join(@current_dir, "logfiles/")
    @text_logfile_path = "#{@logfile_path}/2006-12-21.223606.txt"
    @htm_logfile_path = "#{@logfile_path}/2008-01-15.071445-0500PST.htm"
    @html_logfile_path = "#{@logfile_path}/2008-01-15.071445-0500PST.html"

    @nonexistent_output_dir = File.join(@current_dir, "nonexistent_output_dir/")
    @output_dir = File.join(@current_dir, "output-dir/")
    FileUtils.rm_r(@nonexistent_output_dir, :force => true)
  end

  config.after(:all) do
    # Clean up.
    FileUtils.rm_r(@nonexistent_output_dir, :force => true)
    FileUtils.rm_r(@output_dir, :force => true)
  end
end
