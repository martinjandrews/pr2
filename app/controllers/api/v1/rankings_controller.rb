module Api
  module V1
    class RankingsController < BaseController
      def index
        as_of = parse_as_of(params[:as_of]) || Date.current
        rankings = Rankings.new(as_of: as_of)
        sorted = rankings.player_list.sort_by { |_, points| points[:total] }.reverse

        last_total = nil
        displayed_rank = 0
        results = sorted.each_with_index.map do |(player, points), i|
          displayed_rank = i + 1 if last_total.nil? || last_total != points[:total]
          last_total = points[:total]

          {
            rank: displayed_rank,
            player: { id: player.id, name: player.name },
            last_year_points: points[:last_year].sort.reverse.first(Rankings::TOP_RESULTS_PER_SLOT).sum,
            previous_year_points: points[:previous_year].sort.reverse.first(Rankings::TOP_RESULTS_PER_SLOT).sum,
            total: points[:total]
          }
        end

        render json: results
      end

      private

      def parse_as_of(value)
        Date.parse(value) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
