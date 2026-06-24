class Rankings
  POSITION_POINTS = {
    1 => 120,
    2 => 90,
    3 => 75,
    4 => 60,
    6 => 50,
    8 => 40,
    12 => 30,
    16 => 20,
    24 => 15,
    32 => 10,
    48 => 5
  }.freeze

  TOP_RESULTS_PER_SLOT = 4

  def initialize
    @last_year_editions = []
    @previous_year_editions = []
    @player_points = {}
    Edition.includes(:tournament, placings: :player).order(end_date: :desc).each do |edition|
      if tournament_count(@last_year_editions, edition.tournament) < 1
        @last_year_editions << edition
      elsif tournament_count(@previous_year_editions, edition.tournament) < 1
        @previous_year_editions << edition
      end
    end
  end

  def player_list
    Player.all.each do |player|
      @player_points[player] = { last_year: [], previous_year: [] }
    end
    @last_year_editions.each do |edition|
      edition.placings.each do |placing|
        @player_points[placing.player][:last_year] << (POSITION_POINTS[placing.position] * edition.multiplier).to_i
      end
    end
    @previous_year_editions.each do |edition|
      edition.placings.each do |placing|
        @player_points[placing.player][:previous_year] << (POSITION_POINTS[placing.position] * edition.multiplier).to_i
      end
    end
    @player_points.each_value do |points|
      points[:total] = points[:last_year].max(TOP_RESULTS_PER_SLOT).sum +
                       points[:previous_year].max(TOP_RESULTS_PER_SLOT).sum
    end
  end

  private

  def tournament_count(list, tournament)
    list.count { |e| e.tournament == tournament }
  end
end
