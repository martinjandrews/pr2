require 'test_helper'

class PlacingTest < ActiveSupport::TestCase
  test "valid with position, edition, and player" do
    assert placings(:alice_nationals_2024).valid?
  end

  test "invalid without position" do
    placings(:alice_nationals_2024).position = nil
    refute placings(:alice_nationals_2024).valid?
  end

  test "cannot have two placings for same player in same edition" do
    duplicate = Placing.new(
      position: 3,
      edition: editions(:nationals_2024),
      player: players(:alice)
    )
    refute duplicate.valid?
  end

  test "name returns Winner for position 1" do
    assert_equal "Winner", placings(:alice_nationals_2024).name
  end

  test "name returns Runner up for position 2" do
    assert_equal "Runner up", placings(:bob_nationals_2024).name
  end

  test "name returns Top N for other positions" do
    placing = Placing.new(position: 4)
    assert_equal "Top 4", placing.name
  end
end
