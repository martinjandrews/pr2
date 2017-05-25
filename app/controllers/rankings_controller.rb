class RankingsController < ApplicationController
  def index
    rankings = Rankings.new
    @player_list = rankings.player_list.sort_by {|k,v| v[:total]}.reverse
  end
end