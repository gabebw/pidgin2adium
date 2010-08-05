require "test/unit"

$:.unshift File.dirname(__FILE__) + "/../ext/balance_tags_c"
require "balance_tags_c.so"

class TestBalanceTagsCExtn < Test::Unit::TestCase
  def test_no_balance
    assert_equal "asdf", Pidgin2Adium.balance_tags_c('asdf')
  end

  def test_with_balance
    assert_equal "<p><b>this is unbalanced!</b></p>",
      Pidgin2Adium.balance_tags_c('<p><b>this is unbalanced!')
  end

  # Make sure it doesn't segfault
  def test_run_lots_of_times
    100_000.times do
      assert_equal "<p><b>this is unbalanced!</b></p>",
        Pidgin2Adium.balance_tags_c('<p><b>this is unbalanced!')
    end
  end
end
