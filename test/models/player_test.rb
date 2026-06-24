require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  test "valid with first and last name" do
    assert players(:alice).valid?
  end

  test "invalid without first name" do
    refute Player.new(last_name: "Smith").valid?
  end

  test "invalid without last name" do
    refute Player.new(first_name: "Alice").valid?
  end

  test "name returns full name" do
    assert_equal "Alice Smith", players(:alice).name
  end
end
