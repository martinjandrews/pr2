class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @player_list = Rankings.new.ranked_player_list.first(20)
    @edition = Edition.order(:end_date).last
  end

  def export
    @editions = Edition.all
    @header = "Name"
    @editions.each { |edition| @header += ", #{edition.name}" }

    @placings = Placing.all
    @players = Player.all
  end
end
