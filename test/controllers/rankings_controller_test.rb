require 'test_helper'

class RankingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rankings_url
    assert_response :success
  end

  test "defaults to today when as_of is not given" do
    get rankings_url
    assert_response :success
    assert_select "p", text: "Showing rankings as of #{Date.current.to_fs(:long)}."
  end

  test "renders rankings as of the given date" do
    get rankings_url, params: { as_of: "2023-12-31" }
    assert_response :success

    # Only nationals_2023 (Alice's win, 240 points) has happened by this date.
    assert_select "p", text: "Showing rankings as of December 31, 2023."
    assert_select "td", text: "240"
  end

  test "ignores an invalid as_of value and falls back to today" do
    get rankings_url, params: { as_of: "not-a-date" }
    assert_response :success
    assert_select "p", text: "Showing rankings as of #{Date.current.to_fs(:long)}."
  end
end
