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
    end
  end
end
