require 'csv'

class ImportBaselineResults < ActiveRecord::Migration[7.2]
  class Tournament < ActiveRecord::Base; end
  class Edition < ActiveRecord::Base; 
    belongs_to :tournament; 

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
    ##################################################
    # Tier 1: Major Slams
    ##################################################

    # Kings Cup
    Edition.import('results/kings_cup_2021.csv', 'Kings Cup', 2021, '2021-06-13', '2021-06-13', 1)
    Edition.import('results/kings_cup_2022.csv', 'Kings Cup', 2022, '2022-06-12', '2022-06-13', 1)
    Edition.import('results/kings_cup_2023.csv', 'Kings Cup', 2023, '2023-06-11', '2023-06-12', 1)
    Edition.import('results/kings_cup_2024.csv', 'Kings Cup', 2024, '2024-06-09', '2024-06-10', 1)
    Edition.import('results/kings_cup_2025.csv', 'Kings Cup', 2025, '2025-06-08', '2025-06-09', 1)
    Edition.import('results/kings_cup_2026.csv', 'Kings Cup', 2026, '2026-06-07', '2026-06-08', 1)

    # Slate Pro
    Edition.import('results/slate_pro_2025.csv', 'Slate Pro', 2025, '2025-07-04', '2025-07-06', 1)
    Edition.import('results/slate_pro_2026.csv', 'Slate Pro', 2026, '2026-07-03', '2026-07-05', 1)

    ##################################################
    # Tier 2: Minor Slams
    ##################################################

    # Killer Crossover
    Edition.import('results/killer_crossover_2022.csv', 'Killer Crossover', 2022, '2022-08-12', '2022-08-14', 2)
    Edition.import('results/killer_crossover_2023.csv', 'Killer Crossover', 2023, '2023-08-12', '2023-08-12', 2)
    Edition.import('results/killer_crossover_2024.csv', 'Killer Crossover', 2024, '2024-08-09', '2024-08-11', 2)
    Edition.import('results/killer_crossover_2025.csv', 'Killer Crossover', 2025, '2025-08-08', '2025-08-08', 2)

    # AEBF Singles
    Edition.import('results/aebf_singles_2022.csv', 'AEBF Australian Singles', 2022, '2022-11-19', '2022-11-25', 2)
    Edition.import('results/aebf_singles_2023.csv', 'AEBF Australian Singles', 2023, '2023-10-20', '2023-10-27', 2)
    Edition.import('results/aebf_singles_2024.csv', 'AEBF Australian Singles', 2024, '2024-10-19', '2024-10-25', 2)
    Edition.import('results/aebf_singles_2025.csv', 'AEBF Australian Singles', 2025, '2025-11-15', '2025-11-21', 2)


    ##################################################
    # Tier 3: Major Events
    ##################################################

    # Joybell Cup
    Edition.import('results/joybell_cup_2025.csv', 'Joybell Cup', 2025, '2025-01-26', '2025-01-26', 3)
    Edition.import('results/joybell_cup_2026.csv', 'Joybell Cup', 2026, '2026-01-25', '2026-01-25', 3)

    # Albury Open
    Edition.import('results/albury_open_2024.csv', 'Albury Open', 2024, '2024-03-10', '2024-03-10', 3)
    Edition.import('results/albury_open_2025.csv', 'Albury Open', 2025, '2025-03-09', '2025-03-09', 3)
    Edition.import('results/albury_open_2026.csv', 'Albury Open', 2026, '2026-03-08', '2026-03-08', 3)

    # Tatts Hotel Classic
    Edition.import('results/tatts_hotel_classic_2023.csv', 'Tatts Hotel Classic', 2023, '2023-01-14', '2023-01-15', 3)
    Edition.import('results/tatts_hotel_classic_2024.csv', 'Tatts Hotel Classic', 2024, '2024-01-20', '2024-01-21', 3)
    Edition.import('results/tatts_hotel_classic_2025.csv', 'Tatts Hotel Classic', 2025, '2025-01-11', '2025-01-12', 3)
    Edition.import('results/tatts_hotel_classic_2026.csv', 'Tatts Hotel Classic', 2026, '2026-01-17', '2026-01-18', 3)

    # Geelong Open
    Edition.import('results/geelong_open_2025.csv', 'Geelong Open', 2025, '2025-02-08', '2025-02-09', 3)
    Edition.import('results/geelong_open_2026.csv', 'Geelong Open', 2026, '2026-02-14', '2026-02-15', 3)

    # Berri Open
    Edition.import('results/berri_open_2025.csv', 'Berri Open', 2025, '2025-07-19', '2025-07-20', 3)

    # NT Open
    Edition.import('results/nt_open_2025.csv', 'NT Open', 2025, '2025-01-26', '2025-01-26', 3)
    Edition.import('results/nt_open_2026.csv', 'NT Open', 2026, '2026-01-25', '2026-01-25', 3)

    ##################################################
    # Tier 4: Minor Events
    ##################################################

    # Townsville Open
    Edition.import('results/townsville_open_2024.csv', 'Townsville Open', 2024, '2024-05-19', '2024-05-19', 4)
    Edition.import('results/townsville_open_2025.csv', 'Townsville Open', 2025, '2025-05-18', '2025-05-18', 4)
    Edition.import('results/townsville_open_2026.csv', 'Townsville Open', 2026, '2026-05-17', '2026-05-17', 4)

    # Darwin Open
    Edition.import('results/darwin_open_2021.csv', 'Darwin Open', 2021, '2021-05-02', '2021-05-02', 4)
    Edition.import('results/darwin_open_2022.csv', 'Darwin Open', 2022, '2022-05-01', '2022-05-01', 4)
    Edition.import('results/darwin_open_2023.csv', 'Darwin Open', 2023, '2023-04-30', '2023-04-30', 4)
    Edition.import('results/darwin_open_2024.csv', 'Darwin Open', 2024, '2024-05-05', '2024-05-05', 4)
    Edition.import('results/darwin_open_2025.csv', 'Darwin Open', 2025, '2025-05-04', '2025-05-05', 4)
    Edition.import('results/darwin_open_2026.csv', 'Darwin Open', 2026, '2026-05-03', '2026-05-04', 4)

    # ANZAC
    Edition.import('results/anzac_2026.csv', 'ANZAC', 2026, '2026-04-25', '2026-04-25', 4)

    # Good Friday
    Edition.import('results/good_friday_2026.csv', 'Good Friday', 2026, '2026-04-03', '2026-04-03', 4)

    # Ready's Xmas Cup
    Edition.import('results/readys_xmas_cup_2021.csv', 'Ready\'s Xmas Cup', 2021, '2021-12-11', '2021-12-12', 4)
    Edition.import('results/readys_xmas_cup_2022.csv', 'Ready\'s Xmas Cup', 2022, '2022-12-16', '2022-12-18', 4)
    Edition.import('results/readys_xmas_cup_2023.csv', 'Ready\'s Xmas Cup', 2023, '2023-12-17', '2023-12-17', 4)
    Edition.import('results/readys_xmas_cup_2024.csv', 'Ready\'s Xmas Cup', 2024, '2024-12-15', '2024-12-15', 4)
    Edition.import('results/readys_xmas_cup_2025.csv', 'Ready\'s Xmas Cup', 2026, '2025-12-14', '2025-12-14', 4)

  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
