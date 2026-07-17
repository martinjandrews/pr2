module Api
  module V1
    class TournamentsController < BaseController
      def index
        tournaments = Tournament.includes(:editions).order(:name).map { |tournament| tournament_json(tournament) }
        render json: tournaments
      end

      def show
        tournament = Tournament.find(params[:id])
        render json: tournament_json(tournament)
      end

      private

      def tournament_json(tournament)
        {
          id: tournament.id,
          name: tournament.name,
          description: tournament.description,
          editions: tournament.editions.order(end_date: :desc).map { |edition| edition_summary_json(edition) }
        }
      end

      def edition_summary_json(edition)
        {
          id: edition.id,
          name: edition.name,
          year: edition.year,
          start_date: edition.start_date,
          end_date: edition.end_date,
          tier: edition.tier,
          multiplier: edition.multiplier
        }
      end
    end
  end
end
