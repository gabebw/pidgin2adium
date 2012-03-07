require 'spec_helper'
require 'stringio'

describe Pidgin2Adium::Logger do
  before do
    logger.stubs(:puts)
  end
  let(:output) { StringIO.new }
  let(:logger) { Pidgin2Adium::Logger.new(output) }

  it 'defaults to printing to STDOUT' do
    logger = Pidgin2Adium::Logger.new
    STDOUT.stubs(:puts)
    logger.log('hi')
    STDOUT.should have_received(:puts).with('hi')
  end

  context '#log' do
    it 'immediately outputs a message' do
      logger.log('hi')
      output.string.should == "hi\n"
    end
  end

  context '#warn' do
    it 'puts a warning only when flushed' do
      logger.warn('hi')
      output.string.should == ''
      logger.flush_warnings_and_errors
      output.string.should == "Minor error messages:\nWarning: hi\n"
    end
  end

  context '#error' do
    it 'puts an error only when flushed' do
      logger.error('hi')
      output.string.should == ''
      logger.flush_warnings_and_errors
      output.string.should == "Major error messages:\nError: hi\n"
    end
  end
end
