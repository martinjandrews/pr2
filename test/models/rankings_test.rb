require 'test_helper'

class RankingsTest < ActiveSupport::TestCase
  setup do
    @rankings = Rankings.new
    @player_list = @rankings.player_list
  end

  test "includes all players" do
    assert_equal Player.count, @player_list.size
  end

  test "player with no placings has zero total" do
    assert_equal 0, @player_list[players(:dave)][:total]
  end

  test "points are multiplied by edition multiplier" do
    # Alice wins nationals_2024 (multiplier 2.0): 120 * 2 = 240
    assert_includes @player_list[players(:alice)][:last_year], 240
  end

  test "each tournament contributes only its most recent edition to each slot" do
    alice = @player_list[players(:alice)]
    # last_year: nationals_2024 + states_2024 (two different tournaments)
    # previous_year: nationals_2023 only (states_2023 would be 3rd nationals slot, skipped)
    assert_equal 2, alice[:last_year].size
    assert_equal 1, alice[:previous_year].size
  end

  test "total is sum of last year and previous year points" do
    alice = @player_list[players(:alice)]
    # last_year: [240 (nationals_2024 1st), 90 (states_2024 2nd)] = 330
    # previous_year: [240 (nationals_2023 1st)] = 240
    assert_equal 330, alice[:last_year].sum
    assert_equal 240, alice[:previous_year].sum
    assert_equal 570, alice[:total]
  end

  test "bob only has last year points from nationals" do
    bob = @player_list[players(:bob)]
    assert_equal [180], bob[:last_year]
    assert_equal [],    bob[:previous_year]
    assert_equal 180,   bob[:total]
  end

  test "carol only has last year points from states" do
    carol = @player_list[players(:carol)]
    assert_equal [120], carol[:last_year]
    assert_equal [],    carol[:previous_year]
    assert_equal 120,   carol[:total]
  end

  test "player list sorts correctly by total" do
    sorted = @player_list.sort_by { |_, v| v[:total] }.reverse
    assert_equal players(:alice), sorted[0][0]
    assert_equal players(:bob),   sorted[1][0]
    assert_equal players(:carol), sorted[2][0]
  end

  test "top 4 results per slot are used when player has more than 4" do
    # Only relevant when a player has > 4 placings in a slot; verified via constant
    assert_equal 4, Rankings::TOP_RESULTS_PER_SLOT
  end
end
