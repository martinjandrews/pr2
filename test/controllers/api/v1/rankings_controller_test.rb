require 'test_helper'

module Api
  module V1
    class RankingsControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get api_v1_rankings_url
        assert_response :success
      end

      test "returns rankings as of the given date" do
        get api_v1_rankings_url, params: { as_of: "2023-12-31" }
        assert_response :success

        body = JSON.parse(response.body)
        alice = body.find { |entry| entry["player"]["name"] == players(:alice).name }

        # Only nationals_2023 (Alice's win, 240 points) has happened by this date.
        assert_equal 240, alice["total"]
        assert_equal 240, alice["last_year_points"]
        assert_equal 0, alice["previous_year_points"]
      end

      test "ignores an invalid as_of value and falls back to today" do
        get api_v1_rankings_url, params: { as_of: "not-a-date" }
        assert_response :success

        body = JSON.parse(response.body)
        alice = body.find { |entry| entry["player"]["name"] == players(:alice).name }
        assert_equal 570, alice["total"]
      end

      test "omits previous_rank and previous_total when change_since is not given" do
        get api_v1_rankings_url
        assert_response :success

        body = JSON.parse(response.body)
        assert(body.all? { |entry| entry["previous_rank"].nil? && entry["previous_total"].nil? })
      end

      test "includes previous_rank only for players whose rank changed, but previous_total for everyone compared" do
        # See the equivalent HTML controller test for the full breakdown of
        # this scenario: eve's regionals win vaults her from tied-4th to 2nd,
        # pushing bob, carol and dave down a spot; alice's rank is unaffected.
        get api_v1_rankings_url, params: { as_of: "2030-07-01", change_since: "2024-07-01" }
        assert_response :success

        body = JSON.parse(response.body)
        by_name = body.index_by { |entry| entry["player"]["name"] }

        alice = by_name[players(:alice).name]
        assert_nil alice["previous_rank"]
        assert_equal 570, alice["previous_total"]
        assert_equal 570, alice["total"]

        eve = by_name[players(:eve).name]
        assert_equal 2, eve["rank"]
        assert_equal 4, eve["previous_rank"]
        assert_equal 0, eve["previous_total"]
        assert_equal 360, eve["total"]

        bob = by_name[players(:bob).name]
        assert_equal 3, bob["rank"]
        assert_equal 2, bob["previous_rank"]
        assert_equal 180, bob["previous_total"]
      end

      test "previous_total is shown even when a player's rank hasn't changed" do
        # As of 2024-04-01, states_2024 hasn't happened yet so alice's total
        # is 480; by 2030-07-01 it's grown to 570, but she's #1 both times.
        get api_v1_rankings_url, params: { as_of: "2030-07-01", change_since: "2024-04-01" }
        assert_response :success

        body = JSON.parse(response.body)
        alice = body.find { |entry| entry["player"]["name"] == players(:alice).name }

        assert_equal 1, alice["rank"]
        assert_nil alice["previous_rank"]
        assert_equal 480, alice["previous_total"]
        assert_equal 570, alice["total"]
      end
    end
  end
end
