require 'spec_helper'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'ext', 'balance_tags_c'))
require "balance_tags_c"

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
      text = <<-LATIN
      Sequi unde et nobis ipsum. Expedita temporibus aut adipisci debitis
      porro ducimus. Dignissimos est tenetur vero error voluptatem quidem
      ducimus. Sapiente non occaecati omnis non provident sint ut. Repellat
      laudantium quis aperiam ad fugit accusantium placeat itaque. Quia
      velit voluptatem sint aliquid rem quam occaecati doloremque. Eos
      provident ut suscipit reprehenderit mollitia. Non vitae voluptatem
      laudantium quis a et. In libero voluptas aliquam.Veniam minima
      consequatur quod. Voluptatem quibusdam ut consequatur et ratione
      repellat. Iusto est aspernatur consequatur ex nostrum voluptas
      voluptas et. Rerum voluptas et veritatis ratione voluptates ut iusto
      ut. Aspernatur sed molestiae sint eveniet asperiores mollitia qui.
        Rerum laudantium architecto soluta. Earum qui ut vel corporis ullam
      doloribus voluptatem. Nemo quo recusandae ut. Deleniti vel ea qui ut
      perferendis. Est dolor ducimus voluptatem nemo quis et animi
      reprehenderit. Laudantium voluptas adipisci alias. Ut aut soluta
      repellat consequuntur quidem. Deserunt voluptatem eum eveniet cum.Quia
      consectetur at ut quisquam occaecati et sint. Sint voluptatem quaerat
      qui molestiae ratione voluptatem. Autem labore quos perferendis enim
      fuga deleniti recusandae. Aut libero quo cum autem voluptatem.
      LATIN
      2_000.times do
        Pidgin2Adium.balance_tags_c("<p><b>#{text}").should == "<p><b>#{text}</b></p>"
      end
    end
  end
end
