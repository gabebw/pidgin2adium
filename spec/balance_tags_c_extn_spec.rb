require "spec_helper"

$:.unshift File.dirname(__FILE__) + "/../ext/balance_tags_c"
require "balance_tags_c.so"

describe "BalanceTagsCExtension" do
  describe "text without tags" do
    it "should be left untouched" do
      text = "Foo bar baz, this is my excellent test text!"
      Pidgin2Adium.balance_tags_c(text).should == text
    end
  end

  describe "text with tags" do
    it "should be balanced correctly" do
      Pidgin2Adium.balance_tags_c('<p><b>this is unbalanced!').should == "<p><b>this is unbalanced!</b></p>"
    end

    # Make sure it doesn't segfault
    it "should be balanced correctly when run many times" do
      5_000.times do
        text = Faker::Lorem.paragraphs(3)
        Pidgin2Adium.balance_tags_c("<p><b>#{text}").should == "<p><b>#{text}</b></p>"
      end
    end
  end
end
