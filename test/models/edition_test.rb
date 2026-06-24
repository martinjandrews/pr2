require 'test_helper'

class EditionTest < ActiveSupport::TestCase
  test "valid with all required fields" do
    assert editions(:nationals_2024).valid?
  end

  test "invalid without year" do
    editions(:nationals_2024).year = nil
    refute editions(:nationals_2024).valid?
  end

  test "invalid without tournament" do
    editions(:nationals_2024).tournament = nil
    refute editions(:nationals_2024).valid?
  end

  test "invalid with zero multiplier" do
    editions(:nationals_2024).multiplier = 0
    refute editions(:nationals_2024).valid?
  end

  test "name returns year and tournament name" do
    assert_equal "2024 Australian Nationals", editions(:nationals_2024).name
  end

  test "winner returns player with position 1" do
    assert_equal players(:alice), editions(:nationals_2024).winner
  end

  test "runner_up returns player with position 2" do
    assert_equal players(:bob), editions(:nationals_2024).runner_up
  end

  test "winner returns nil when no placings" do
    assert_nil editions(:states_2023).winner
  end
end
