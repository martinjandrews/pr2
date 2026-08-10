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

  test "does not show a comparison when change_since is not given" do
    get rankings_url
    assert_response :success
    assert_select ".text-success", false
    assert_select ".text-danger", false
    assert_select "th", text: "Change", count: 0
  end

  test "shows rank changes when change_since is given" do
    # As of 2024-07-01: alice 1st, bob 2nd, carol 3rd, dave/eve tied last (4th).
    # As of 2030-07-01: eve's regionals win (360pts) vaults her from tied-4th
    # to 2nd, pushing bob, carol and dave down a spot; alice is unaffected.
    get rankings_url, params: { as_of: "2030-07-01", change_since: "2024-07-01" }
    assert_response :success

    assert_select "p", text: "Showing rankings as of July 01, 2030. Comparing against July 01, 2024."

    # Eve improved from (tied) rank 4 to rank 2.
    assert_select "td.text-center span.text-success", text: "▲ 4"
    # Bob, carol and dave each worsened by one place, with no points change.
    assert_select "td.text-center span.text-danger", text: "▼ 2", count: 1
    assert_select "td.text-center span.text-danger", text: "▼ 3", count: 1
    assert_select "td.text-center span.text-danger", text: "▼ 4", count: 1
    assert_select "th", text: "Change", count: 2
    assert_select "td.text-right span.text-success", text: "+360"
    # Alice's rank is unchanged, but the points diff (0) still shows, along
    # with bob, carol and dave whose points also didn't change.
    assert_select "td.text-right span.text-success", text: "+0", count: 4
  end

  test "shows the points diff even when a player's rank hasn't changed" do
    # As of 2024-04-01, states_2024 hasn't happened yet so alice's total is
    # 480; by 2030-07-01 it's grown to 570, but she's #1 both times, so no
    # rank-change arrow should render for her - just the points diff.
    get rankings_url, params: { as_of: "2030-07-01", change_since: "2024-04-01" }
    assert_response :success

    row = Nokogiri::HTML(response.body).css("tr").find { |tr| tr.text.include?(players(:alice).name) }
    assert_nil row.at_css("td.text-center span.text-success, td.text-center span.text-danger")
    assert_equal "+90", row.at_css("td.text-right span").text
  end
end
