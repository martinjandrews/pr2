class HomeController < ApplicationController
  def index
    rankings = Rankings.new
    @player_list = rankings.player_list.sort_by { |k, v| v[:total] }.reverse[0..19]
    @edition = Edition.all.sort_by { |each| each.end_date }.last
  end
end