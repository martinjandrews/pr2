require 'test_helper'

class PlacingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
    @placing = placings(:alice_nationals_2024)
  end

  test "should get index" do
    get placings_url
    assert_response :success
  end

  test "should get new" do
    get new_placing_url(edition_id: editions(:nationals_2024).id)
    assert_response :success
  end

  test "should create placing" do
    assert_difference('Placing.count') do
      post placings_url, params: { placing: {
        position: 4,
        edition_id: editions(:nationals_2024).id,
        player_id: players(:carol).id
      } }
    end
    assert_redirected_to edition_url(Placing.last.edition)
  end

  test "should show placing" do
    get placing_url(@placing)
    assert_response :success
  end

  test "should get edit" do
    get edit_placing_url(@placing)
    assert_response :success
  end

  test "should update placing" do
    patch placing_url(@placing), params: { placing: { position: @placing.position } }
    assert_redirected_to edition_url(@placing.edition)
  end

  test "should destroy placing" do
    assert_difference('Placing.count', -1) do
      delete placing_url(@placing)
    end
    assert_redirected_to placings_url
  end
end
