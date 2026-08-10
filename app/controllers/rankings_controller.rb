class RankingsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @as_of = parse_as_of(params[:as_of]) || Date.current
    rankings = Rankings.new(as_of: @as_of)
    @player_list = rankings.player_list.sort_by {|k,v| v[:total]}.reverse
  end

  private

  def parse_as_of(value)
    Date.parse(value) if value.present?
  rescue ArgumentError
    nil
  end
end