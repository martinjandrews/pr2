class Edition < ApplicationRecord
  belongs_to :tournament
  has_many :placings, dependent: :destroy

  validates :year, :start_date, :end_date, :tier, :tournament, presence: true
  validates :tier, numericality: { greater_than: 0 }, allow_blank: true

  TIER_MULTIPLIER = {
    1 => 4,
    2 => 3,
    3 => 2,
    4 => 1
  }.freeze

  def name
    "#{year} #{tournament.name}"
  end

  def winner
    sorted_placings.first&.player
  end

  def runner_up
    sorted_placings.second&.player
  end

  def multiplier
    TIER_MULTIPLIER[tier] || TIER_MULTIPLIER.values.min
  end

  def self.import(placings_filename, tournament_name, year, start_date, end_date, tier)
    tournament = Tournament.find_or_create_by!(name: tournament_name)

    edition = Edition.find_or_initialize_by(tournament: tournament, year: year)
    edition.assign_attributes(start_date: start_date, end_date: end_date, tier: tier)
    edition.save!

    puts "  Edition: #{edition.name} (#{start_date} – #{end_date}, #{tier})"

    placing_rows = CSV.read(placings_filename, headers: true)
    created = skipped = 0

    placing_rows.each do |row|
      position    = row['position'].to_i
      player_name = row['player_name'].strip
      next if player_name.empty?

      first, *rest = player_name.split(' ')
      last = rest.join(' ')
      player = Player.find_or_create_by!(first_name: first, last_name: last)

      if Placing.exists?(edition: edition, player: player)
        skipped += 1
        next
      end

      Placing.create!(edition: edition, player: player, position: position)
      created += 1
    end
    
    puts "  #{created} placings created, #{skipped} already existed"
  end

  private

  def sorted_placings
    placings.order(:position)
  end
end
