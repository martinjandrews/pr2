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

  TOP_RESULTS_PER_SLOT = 3

  def initialize(as_of: Date.current)
    @as_of = as_of
    @last_year_editions = []
    @previous_year_editions = []
    @player_points = {}
    Edition.includes(:tournament, placings: :player).where(end_date: ..@as_of).order(end_date: :desc).each do |edition|
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

  def ranked_player_list
    sorted = player_list.sort_by { |_, points| points[:total] }.reverse
    last_total = nil
    displayed_rank = 1
    sorted.each_with_index.each_with_object({}) do |((player, points), i), ranked|
      displayed_rank = i + 1 if last_total.nil? || last_total != points[:total]
      last_total = points[:total]
      ranked[player] = points.merge(rank: displayed_rank)
    end
  end

  def rank_for(player)
    points = ranked_player_list[player]
    points && { rank: points[:rank], total: points[:total] }
  end

  private

  def tournament_count(list, tournament)
    list.count { |e| e.tournament == tournament }
  end
end
