module Api
  module V1
    class RankingsController < BaseController
      def index
        rankings = Rankings.new
        sorted = rankings.player_list.sort_by { |_, points| points[:total] }.reverse

        last_total = nil
        displayed_rank = 0
        results = sorted.each_with_index.map do |(player, points), i|
          displayed_rank = i + 1 if last_total.nil? || last_total != points[:total]
          last_total = points[:total]

          {
            rank: displayed_rank,
            player: { id: player.id, name: player.name },
            last_year_points: points[:last_year].sort.reverse.first(4).sum,
            previous_year_points: points[:previous_year].sort.reverse.first(4).sum,
            total: points[:total]
          }
        end

        render json: results
      end
    end
  end
end
