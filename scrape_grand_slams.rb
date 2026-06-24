#!/usr/bin/env ruby
# Scrapes final standings (placings) from poolstat.net.au grand slam pages
# and outputs CSV files with position,player_name for import into the pr2
# ranking system.
#
# For /knockout/ URLs the bracket is parsed directly.
# For /matches/ URLs the companion /finals/ page is fetched; its format
# (knockout bracket or individual match list) is detected automatically.
#
# Usage (single): ruby scrape_grand_slams.rb <url> [output.csv]
# Usage (bulk):   ruby scrape_grand_slams.rb --file <urls.csv>
#
# The URL file format matches urls-grand-slams.csv: url,output columns,
# with blank lines and # comments ignored.

require 'net/http'
require 'uri'
require 'csv'
require 'date'
require 'fileutils'

SCRIPT_DIR  = __dir__
RESULTS_DIR = File.join(SCRIPT_DIR, 'results')
DEFAULT_URL_FILE = File.join(SCRIPT_DIR, 'urls-grand-slams.csv')
FileUtils.mkdir_p(RESULTS_DIR)

USAGE = "Usage: ruby scrape_grand_slams.rb [--file <urls.csv>]\n" \
        "       ruby scrape_grand_slams.rb <url> [output.csv]\n" \
        "Defaults to urls-grand-slams.csv in the same directory as this script."

# ---------------------------------------------------------------------------- helpers

def fetch_html(url, silent: false)
  response = Net::HTTP.get_response(URI(url))
  unless response.is_a?(Net::HTTPSuccess)
    warn "  HTTP #{response.code} from #{url}" unless silent
    return nil
  end
  response.body
rescue => e
  warn "  Error fetching #{url}: #{e.message}" unless silent
  nil
end

def knockout_bracket?(html)
  html.include?('class="player homecell') && html.include?('data-id="cell_')
end

# ---------------------------------------------------------------------------- core placer
#
# Given a hash of { key => { winner: name, loser: name } } where keys are
# comparable (integer match codes or document-order indices), traces the
# bracket topology and returns [[position, player_name], ...].
#
# The bracket topology is inferred from each player's sequence of match keys:
# if a player appears in matches A then B (A < B), match A feeds into B.
# BFS from the final (highest key) assigns round depth (0 = final, 1 = semi, …).

PLACEHOLDER_NAMES = %w[BYE TBD].to_set

def placings_from_matches(matches)
  return [] if matches.empty?

  # Exclude placeholder names (BYE, TBD) from player tracking: their long chains
  # across many bracket slots corrupt the feeds_into topology. The matches
  # themselves stay in the hash so real players' consecutive-code chains remain
  # intact (e.g. player beat BYE in match A then played real opponent in match B).
  player_keys = Hash.new { |h, k| h[k] = [] }
  matches.each do |key, m|
    player_keys[m[:winner]] << key unless PLACEHOLDER_NAMES.include?(m[:winner])
    player_keys[m[:loser]]  << key unless PLACEHOLDER_NAMES.include?(m[:loser])
  end

  feeds_into = {}
  player_keys.each_value do |keys|
    keys.sort.each_cons(2) { |a, b| feeds_into[a] ||= b }
  end

  # Prefer the highest-coded match on the latest date. This handles tournaments
  # where match codes don't sort chronologically (e.g. a lower-grade match may
  # receive a higher code than the main-grade final).
  last_date = matches.values.map { |m| m[:date] }.compact.max
  candidates = last_date ? matches.select { |_, m| m[:date] == last_date } : matches
  final_key  = candidates.keys.max || matches.keys.max

  fed_by = Hash.new { |h, k| h[k] = [] }
  feeds_into.each { |from, to| fed_by[to] << from }

  match_round = {}
  queue = [[final_key, 0]]
  until queue.empty?
    key, round = queue.shift
    next if match_round.key?(key)
    match_round[key] = round
    fed_by[key].each { |prev| queue << [prev, round + 1] }
  end

  placings = [[1, matches[final_key][:winner]]]
  position = 2

  (0..match_round.values.max).each do |round|
    round_keys   = match_round.select { |_, r| r == round }.keys.sort
    round_losers = round_keys.map { |k| matches[k][:loser] }.compact
                             .reject { |p| PLACEHOLDER_NAMES.include?(p) }
    round_losers.each_with_index { |player, i| placings << [position + i, player] }
    position += round_losers.size
  end

  placings.sort_by! { |pos, _| pos }

  # In double-elimination formats a player can lose in the winners bracket, recover
  # through the losers bracket, and win the whole tournament — producing duplicate
  # entries. Keep only each player's best (lowest) position, then renumber.
  seen = {}
  placings = placings.each_with_object([]) do |(pos, player), result|
    next if seen[player]
    seen[player] = true
    result << [pos, player]
  end
  placings.each_with_index.map { |(_, player), i| [i + 1, player] }
end

# ---------------------------------------------------------------------------- knockout bracket parser

def scrape_knockout(html)
  players = {}
  html.scan(/<td id="(cell_\d+_[HA])"[^>]*class="player[^"]*"[^>]*>(.*?)<\/td>/m) do |cell_id, cell_html|
    players[cell_id] = cell_html.gsub(/<[^>]+>/, '').strip
  end

  scores = {}
  html.scan(/<td[^>]*class="score new[^"]*"[^>]*data-id="(cell_\d+_[HA])"[^>]*>(\d+)<\/td>/) do |cell_id, score|
    scores[cell_id] = score.to_i
  end

  # Extract per-match dates from the embedded dataDraws JSON blob.
  # Format: "CODE":["CODE","...","...","YYYY-MM-DD",...]
  match_dates = {}
  html.scan(/"(\d+)":\["[^"]*","[^"]*","[^"]*","(\d{4}-\d{2}-\d{2})"/) do |code, date|
    match_dates[code.to_i] = date
  end

  matches = {}
  players.keys.map { |k| k[/cell_(\d+)_/, 1] }.uniq.each do |code|
    h_id = "cell_#{code}_H"
    a_id = "cell_#{code}_A"
    next unless players[h_id] && players[a_id]
    next unless scores[h_id] && scores[a_id]
    next if scores[h_id] == 0 && scores[a_id] == 0
    next if players[h_id].empty? || players[a_id].empty?

    matches[code.to_i] = if scores[h_id] > scores[a_id]
      { winner: players[h_id], loser: players[a_id], date: match_dates[code.to_i] }
    else
      { winner: players[a_id], loser: players[h_id], date: match_dates[code.to_i] }
    end
  end

  placings_from_matches(matches)
end

# ---------------------------------------------------------------------------- individual match list parser (finals page fallback)

def extract_date_positions(html)
  positions = []
  html.scan(/(\d{2}-\d{2}-\d{4}) - (?:[^<]*?)(?:Round|\w+ Final)/) do
    positions << [Regexp.last_match.begin(0),
                  Date.strptime(Regexp.last_match(1), '%d-%m-%Y').strftime('%Y-%m-%d')]
  end
  positions
end

def scrape_finals_individual(html)
  date_positions = extract_date_positions(html)
  raw_matches = []

  pattern = /
    <td[^>]*hometeam[^>]*>(.*?)<\/td>
    \s*
    <td[^>]*score[^>]*hscore[^>]*>(.*?)<\/td>
    \s*
    <td[^>]*awayteam[^>]*>(.*?)<\/td>
  /xm

  html.scan(pattern) do |home_html, score_html, away_html|
    pos = Regexp.last_match.begin(0)
    next if away_html.include?('BYE') || score_html.include?('NR')

    spans = score_html.scan(/<span class="csc-score-[^"]*">(.*?)<\/span>/m)
                      .flatten.map { |s| s.gsub(/<[^>]+>/, '').strip }
    next if spans.size < 2

    home_score = spans[0][/\((\d+)\)/, 1]&.to_i || spans[0][/\A\s*(\d+)\s*\z/, 1]&.to_i
    away_score = spans[1][/\((\d+)\)/, 1]&.to_i || spans[1][/\A\s*(\d+)\s*\z/, 1]&.to_i
    next unless home_score && away_score

    home = home_html.gsub(/<[^>]+>/, '').strip
    away = away_html.gsub(/<[^>]+>/, '').strip
    next if home.empty? || away.empty?

    raw_matches << { pos: pos, home: home, away: away,
                     home_score: home_score, away_score: away_score }
  end

  # Index matches by document position (chronological for finals pages).
  matches = {}
  raw_matches.each_with_index do |m, idx|
    matches[idx] = if m[:home_score] > m[:away_score]
      { winner: m[:home], loser: m[:away] }
    else
      { winner: m[:away], loser: m[:home] }
    end
  end

  placings_from_matches(matches)
end

# ---------------------------------------------------------------------------- per-URL scrape

def scrape_placings(url)
  if url.include?('/knockout/')
    html = fetch_html(url)
    return [] unless html
    unless knockout_bracket?(html)
      warn "  Not a recognized knockout bracket — skipping"
      return []
    end
    scrape_knockout(html)

  elsif url.include?('/matches/')
    finals_url = url.sub('/matches/', '/finals/')
    puts "  Fetching finals: #{finals_url}"
    finals_html = fetch_html(finals_url)

    placings = if finals_html && knockout_bracket?(finals_html)
      scrape_knockout(finals_html)
    elsif finals_html
      scrape_finals_individual(finals_html)
    else
      []
    end

    if placings.empty?
      # Finals page is empty or unpopulated; parse the full bracket from the matches page.
      puts "  Finals page empty — trying matches page"
      html = fetch_html(url)
      placings = html ? scrape_finals_individual(html) : []
    end

    placings

  else
    warn "  Unsupported URL — expected /knockout/ or /matches/"
    []
  end
end

# ---------------------------------------------------------------------------- argument parsing

def load_url_file(path)
  abort "File not found: #{path}" unless File.exist?(path)
  content = File.readlines(path, chomp: true)
                .reject { |l| l.strip.empty? || l.strip.start_with?('#') }
                .join("\n")
  rows = CSV.parse(content, headers: true)
  abort "No URLs found in #{path}" if rows.empty?
  rows.filter_map do |row|
    url    = row['url']&.strip
    next if url.nil? || url.empty?
    prefix = (row['output_prefix'] || row['output'])&.strip
    filename = prefix && !prefix.empty? ? "#{prefix}.csv" : "#{url.split('/').last.tr('-', '_')}.csv"
    [url, File.join(RESULTS_DIR, filename)]
  end
end

if ARGV.include?('--file')
  file_arg = ARGV[ARGV.index('--file') + 1]
  abort USAGE unless file_arg
  urls_with_outputs = load_url_file(file_arg)

elsif ARGV[0] && ARGV[0].start_with?('http')
  url      = ARGV[0]
  filename = ARGV[1] || "#{url.split('/').last.tr('-', '_')}.csv"
  urls_with_outputs = [[url, File.join(RESULTS_DIR, filename)]]

else
  urls_with_outputs = load_url_file(DEFAULT_URL_FILE)
end

# ---------------------------------------------------------------------------- main loop

urls_with_outputs.each do |url, output|
  puts "\n#{output}"
  puts "  Fetching: #{url}"

  placings = scrape_placings(url)

  if placings.empty?
    warn "  No placings found — skipping"
    next
  end

  puts "  #{placings.size} placings found"
  CSV.open(output, 'w') do |csv|
    csv << %w[position player_name]
    placings.each { |row| csv << row }
  end
  puts "  Wrote #{placings.size} placings to #{output}"
end
