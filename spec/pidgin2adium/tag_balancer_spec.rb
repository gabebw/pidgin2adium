require 'spec_helper'

describe Pidgin2Adium::TagBalancer do
  describe "text without tags" do
    it "should be left untouched" do
      text = "Foo bar baz, this is my excellent test text!"
      Pidgin2Adium::TagBalancer.new(text).balance.should == text
    end
  end

  describe "text with tags" do
    it "should be balanced correctly" do
      unbalanced = '<p><b>this is unbalanced!'
      balanced   = "<p><b>this is unbalanced!</b></p>"
      Pidgin2Adium::TagBalancer.new(unbalanced).balance.should == balanced
    end
  end
end
