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
  }

  def initialize
    @last_year_editions = []
    @previous_year_editions = []
    @player_points = {}
    Edition.all.sort_by{|each| each.end_date}.reverse.each do |edition|
      if tournament_count(@last_year_editions, edition.tournament) < 1
          @last_year_editions << edition
      elsif tournament_count(@previous_year_editions, edition.tournament) < 1
          @previous_year_editions << edition
      end
    end
  end

  def player_list
    Player.all.each do |player|
      @player_points[player] = {last_year: [], previous_year: []}
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
    @player_points.each do |player, points_hash|
      points_hash[:total] = 0
      points_hash[:total] += points_hash[:last_year].sort.reverse.first(4).sum
      points_hash[:total] += points_hash[:previous_year].sort.reverse.first(4).sum
    end
  end

  private

  def tournament_count(list, tournament)
    list.count{|each| each.tournament == tournament}
  end
end