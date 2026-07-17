module Api
  module V1
    class PlayersController < BaseController
      def index
        players = Player.order(:last_name, :first_name).map { |player| { id: player.id, name: player.name } }
        render json: players
      end

      def show
        player = Player.find(params[:id])
        rankings = Rankings.new
        ranking = rankings.rank_for(player)
        used_placings = rankings.used_placings_for(player)

        placings = player.placings.includes(edition: :tournament).sort_by { |placing| placing.edition.end_date }.reverse.map do |placing|
          {
            id: placing.id,
            position: placing.position,
            position_label: placing.name,
            points: Rankings.points_for(placing),
            counted_towards_ranking: used_placings.include?(placing),
            edition: {
              id: placing.edition.id,
              name: placing.edition.name,
              year: placing.edition.year,
              end_date: placing.edition.end_date
            }
          }
        end

        render json: {
          id: player.id,
          name: player.name,
          rank: ranking&.fetch(:rank),
          total_points: ranking&.fetch(:total),
          placings: placings
        }
      end
    end
  end
end
