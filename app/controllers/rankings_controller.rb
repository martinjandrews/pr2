class RankingsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @as_of = parse_as_of(params[:as_of]) || Date.current
    @change_since = parse_as_of(params[:change_since])

    @player_list = Rankings.new(as_of: @as_of).ranked_player_list
    @previous_player_list = Rankings.new(as_of: @change_since).ranked_player_list if @change_since
  end

  private

  def parse_as_of(value)
    Date.parse(value) if value.present?
  rescue ArgumentError
    nil
  end
end