module Api
  module V1
    class RankingsController < BaseController
      def index
        as_of = parse_as_of(params[:as_of]) || Date.current
        change_since = parse_as_of(params[:change_since])

        ranked_player_list = Rankings.new(as_of: as_of).ranked_player_list
        previous_ranked_player_list = Rankings.new(as_of: change_since).ranked_player_list if change_since

        results = ranked_player_list.map do |player, points|
          previous = previous_ranked_player_list && previous_ranked_player_list[player]
          changed = previous && previous[:rank] != points[:rank]

          {
            rank: points[:rank],
            player: { id: player.id, name: player.name },
            last_year_points: points[:last_year].sort.reverse.first(Rankings::TOP_RESULTS_PER_SLOT).sum,
            previous_year_points: points[:previous_year].sort.reverse.first(Rankings::TOP_RESULTS_PER_SLOT).sum,
            total: points[:total],
            previous_rank: changed ? previous[:rank] : nil,
            previous_total: changed ? previous[:total] : nil
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
