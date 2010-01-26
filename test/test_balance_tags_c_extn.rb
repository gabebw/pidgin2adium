require "test/unit"

$:.unshift File.dirname(__FILE__) + "/../ext/balance_tags_c"
require "balance_tags_c.so"

class TestBalanceTagsCExtn < Test::Unit::TestCase
  def test_truth
    assert true
  end
end