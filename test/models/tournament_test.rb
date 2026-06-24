require 'test_helper'

class TournamentTest < ActiveSupport::TestCase
  test "valid with name" do
    assert tournaments(:nationals).valid?
  end

  test "invalid without name" do
    refute Tournament.new(description: "no name").valid?
  end
end
