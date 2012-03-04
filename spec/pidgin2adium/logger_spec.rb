require 'spec_helper'
require 'stringio'

describe Pidgin2Adium::Logger do
  before do
    logger.stubs(:puts)
  end
  let(:output) { StringIO.new }
  let(:logger) { Pidgin2Adium::Logger.new(output) }

  it 'defaults to printing to $STDOUT' do
    logger = Pidgin2Adium::Logger.new
    $STDOUT.stubs(:puts)
    logger.log('hi')
    logger.flush
    $STDOUT.should have_received(:puts).with('hi')
  end

  context '#log' do
    it 'puts a message only when flushed' do
      logger.log('hi')
      output.string.should == ''
      logger.flush
      output.string.should == "hi\n"
    end
  end

  context '#oops' do
    it 'puts an Oops message only when flushed' do
      logger.oops('hi')
      output.string.should == ''
      logger.flush
      output.string.should == "Minor error messages:\nOops: hi\n"
    end
  end

  context '#error' do
    it 'puts an error message when flushed' do
      logger.error('hi')
      output.string.should == ''
      logger.flush
      output.string.should == "Major error messages:\nError: hi\n"
    end
  end
end
