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

      Edition.import(file, t_name, year, start_date, end_date, tier)
    end

    puts "\nDone."
  end
end
