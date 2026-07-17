module Api
  module V1
    class EditionsController < BaseController
      def index
        editions = Edition.includes(:tournament).order(end_date: :desc).map { |edition| edition_json(edition) }
        render json: editions
      end

      def show
        edition = Edition.includes(:tournament, placings: :player).find(params[:id])

        placings = edition.placings.sort_by(&:position).map do |placing|
          {
            id: placing.id,
            position: placing.position,
            position_label: placing.name,
            points: Rankings.points_for(placing),
            player: { id: placing.player.id, name: placing.player.name }
          }
        end

        render json: edition_json(edition).merge(placings: placings)
      end

      private

      def edition_json(edition)
        {
          id: edition.id,
          name: edition.name,
          year: edition.year,
          start_date: edition.start_date,
          end_date: edition.end_date,
          tier: edition.tier,
          multiplier: edition.multiplier,
          tournament: { id: edition.tournament.id, name: edition.tournament.name }
        }
      end
    end
  end
end
