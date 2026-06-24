class RankingsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    rankings = Rankings.new
    @player_list = rankings.player_list.sort_by {|k,v| v[:total]}.reverse
  end
end