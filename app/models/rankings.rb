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

  def self.points_for(placing)
    key = POSITION_POINTS.key?(placing.position) ? placing.position : POSITION_POINTS.keys.select { |k| k > placing.position }.min
    key ? (POSITION_POINTS[key] * placing.edition.multiplier).to_i : 0
  end

  def player_list
    Player.all.each do |player|
      @player_points[player] = { last_year: [], previous_year: [] }
    end
    @last_year_editions.each do |edition|
      edition.placings.each do |placing|
        @player_points[placing.player][:last_year] << Rankings.points_for(placing)
      end
    end
    @previous_year_editions.each do |edition|
      edition.placings.each do |placing|
        @player_points[placing.player][:previous_year] << Rankings.points_for(placing)
      end
    end
    @player_points.each_value do |points|
      points[:total] = points[:last_year].max(TOP_RESULTS_PER_SLOT).sum +
                       points[:previous_year].max(TOP_RESULTS_PER_SLOT).sum
    end
  end

  def used_placings_for(player)
    last_year_ids = @last_year_editions.map(&:id).to_set
    prev_year_ids = @previous_year_editions.map(&:id).to_set

    all = player.placings.includes(:edition)
    last_placings = all.select { |p| last_year_ids.include?(p.edition_id) }
    prev_placings = all.select { |p| prev_year_ids.include?(p.edition_id) }

    (last_placings.sort_by { |p| -Rankings.points_for(p) }.first(TOP_RESULTS_PER_SLOT) +
     prev_placings.sort_by { |p| -Rankings.points_for(p) }.first(TOP_RESULTS_PER_SLOT)).to_set
  end

  def rank_for(player)
    sorted = player_list.sort_by { |_, v| v[:total] }.reverse
    displayed_rank = 1
    last_total = nil
    sorted.each_with_index do |(p, points), i|
      displayed_rank = i + 1 if last_total.nil? || last_total != points[:total]
      return { rank: displayed_rank, total: points[:total] } if p == player
      last_total = points[:total]
    end
    nil
  end

  private

  def tournament_count(list, tournament)
    list.count { |e| e.tournament == tournament }
  end
end
