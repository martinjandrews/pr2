require 'test_helper'

class PlacingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @placing = placings(:one)
  end

  test "should get index" do
    get placings_url
    assert_response :success
  end

  test "should get new" do
    get new_placing_url
    assert_response :success
  end

  test "should create placing" do
    assert_difference('Placing.count') do
      post placings_url, params: { placing: { edition_id: @placing.edition_id, player_id: @placing.player_id, position: @placing.position } }
    end

    assert_redirected_to placing_url(Placing.last)
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
    patch placing_url(@placing), params: { placing: { edition_id: @placing.edition_id, player_id: @placing.player_id, position: @placing.position } }
    assert_redirected_to placing_url(@placing)
  end

  test "should destroy placing" do
    assert_difference('Placing.count', -1) do
      delete placing_url(@placing)
    end

    assert_redirected_to placings_url
  end
end
