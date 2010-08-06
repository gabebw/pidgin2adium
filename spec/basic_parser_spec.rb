require 'spec_helper'

describe "BasicParser" do
  it "should include Pidgin2Adium" do
    Pidgin2Adium::BasicParser.included_modules.include?(Pidgin2Adium).should be_true
  end
end
