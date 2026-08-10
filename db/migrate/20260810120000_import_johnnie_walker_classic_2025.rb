require 'csv'

class ImportJohnnieWalkerClassic2025 < ActiveRecord::Migration[7.2]
  class Tournament < ActiveRecord::Base; end
  class Edition < ActiveRecord::Base
    belongs_to :tournament

    def self.import(placings_filename, tournament_name, year, start_date, end_date, tier)
      tournament = Tournament.find_or_create_by!(name: tournament_name)

      edition = Edition.find_or_initialize_by(tournament: tournament, year: year)
      edition.assign_attributes(start_date: start_date, end_date: end_date, tier: tier)
      edition.save!

      puts "  Edition: #{tournament_name} - #{year}  (#{start_date} – #{end_date}, #{tier})"

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
  end
  class Player < ActiveRecord::Base; end
  class Placing < ActiveRecord::Base; belongs_to :edition; belongs_to :player; end

  def up
    Edition.import('results/johnnie_walker_classic_2025.csv', 'Johnnie Walker Classic', 2025, '2025-08-23', '2025-08-24', 4)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
