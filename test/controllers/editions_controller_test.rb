require 'test_helper'

class EditionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
    @edition = editions(:nationals_2024)
  end

  test "should get index" do
    get editions_url
    assert_response :success
  end

  test "should get new" do
    get new_edition_url(tournament_id: tournaments(:nationals).id)
    assert_response :success
  end

  test "should create edition" do
    assert_difference('Edition.count') do
      post editions_url, params: { edition: {
        year: 2022,
        start_date: "2022-06-01",
        end_date: "2022-06-02",
        multiplier: 1.0,
        tournament_id: tournaments(:states).id
      } }
    end
    assert_redirected_to tournament_url(Edition.last.tournament)
  end

  test "should show edition" do
    get edition_url(@edition)
    assert_response :success
  end

  test "should get edit" do
    get edit_edition_url(@edition)
    assert_response :success
  end

  test "should update edition" do
    patch edition_url(@edition), params: { edition: { year: @edition.year } }
    assert_redirected_to tournament_url(@edition.tournament)
  end

  test "should destroy edition" do
    assert_difference('Edition.count', -1) do
      delete edition_url(@edition)
    end
    assert_redirected_to tournament_url(@edition.tournament)
  end
end
