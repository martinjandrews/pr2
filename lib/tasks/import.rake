require 'csv'

namespace :import do
  desc "Import grand slam placings from import.csv into the database"
  task placings: :environment do
    meta_path = Rails.root.join('import.csv')
    abort "import.csv not found at #{meta_path}" unless File.exist?(meta_path)

    content = File.readlines(meta_path, chomp: true)
                  .reject { |l| l.strip.empty? || l.strip.start_with?('#') }
                  .join("\n")
    rows = CSV.parse(content, headers: true)

    rows.each do |meta|
      file       = Rails.root.join(meta['file'])
      t_name     = meta['tournament'].strip
      year       = meta['year'].to_i
      start_date = Date.parse(meta['start_date'])
      end_date   = Date.parse(meta['end_date'])
      tier       = meta['tier'].to_i

      unless File.exist?(file)
        warn "  SKIP #{meta['file']} — file not found"
        next
      end

      puts "\n#{t_name} #{year}"

      tournament = Tournament.find_or_create_by!(name: t_name)

      edition = Edition.find_or_initialize_by(tournament: tournament, year: year)
      edition.assign_attributes(start_date: start_date, end_date: end_date, tier: tier)
      edition.save!
      puts "  Edition: #{edition.name} (#{start_date} – #{end_date}, #{tier})"

      placing_rows = CSV.read(file, headers: true)
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

    puts "\nDone."
  end
end
