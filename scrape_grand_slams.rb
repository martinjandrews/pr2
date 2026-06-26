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
require 'json'

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

# Parses the bracket feeds from the embedded dataDraws JSON blob.
# Returns [feeds_winner, feeds_loser] where each is a hash of
# match_code => next_match_code. Returns [{}, {}] if feeds are absent or
# all zero (as with single-draw tournaments that don't encode connectivity).
def parse_bracket_feeds(html)
  json_str = html[/id="dataDraws">(\{.+?\})<\/div>/m, 1]
  return [{}, {}] unless json_str

  data = JSON.parse(json_str)
  feeds_winner = {}
  feeds_loser  = {}
  data.each do |code_str, val|
    next unless val.is_a?(Array) && val.size > 44
    code  = code_str.to_i
    w_int = val[42].to_s.to_i
    l_int = val[44].to_s.to_i
    feeds_winner[code] = w_int if w_int > 0
    feeds_loser[code]  = l_int if l_int > 0
  end
  [feeds_winner, feeds_loser]
rescue JSON::ParserError
  [{}, {}]
end

# Given a hash of { key => { winner:, loser:, date: } } traces the bracket
# topology and returns [[position, player_name], ...].
#
# When feeds_winner / feeds_loser are provided (parsed from dataDraws JSON)
# they are used directly to build the backward-edge graph and detect terminal
# matches. This handles multi-draw formats (e.g. double-elimination with
# separate winners/losers bracket draws) where the single-final heuristic
# fails. Falls back to inferring topology from player consecutive match codes
# when the feeds maps are empty (single-draw tournaments).
def placings_from_matches(matches, feeds_winner: {}, feeds_loser: {})
  return [] if matches.empty?

  fed_by = Hash.new { |h, k| h[k] = [] }

  if feeds_winner.any?
    # Explicit feeds from dataDraws JSON: build backward edges and find
    # terminal matches (completed matches whose winner doesn't advance to
    # another completed match on this page).
    feeds_winner.each do |from, to|
      next unless matches.key?(from) && matches.key?(to)
      fed_by[to] << from
    end
    feeds_loser.each do |from, to|
      next unless matches.key?(from) && matches.key?(to)
      fed_by[to] << from
    end
    terminal_keys = matches.keys.select { |c|
      w = feeds_winner[c]
      w.nil? || !matches.key?(w)
    }.sort
  else
    # Fallback: infer topology from each player's sequence of match codes.
    # Exclude BYE/TBD — their chains across many bracket slots corrupt the
    # inferred feeds_into graph.
    player_keys = Hash.new { |h, k| h[k] = [] }
    matches.each do |key, m|
      player_keys[m[:winner]] << key unless PLACEHOLDER_NAMES.include?(m[:winner])
      player_keys[m[:loser]]  << key unless PLACEHOLDER_NAMES.include?(m[:loser])
    end
    inferred_feeds = {}
    player_keys.each_value do |keys|
      keys.sort.each_cons(2) { |a, b| inferred_feeds[a] ||= b }
    end
    inferred_feeds.each { |from, to| fed_by[to] << from }

    # Prefer the highest-coded match on the latest date (handles multi-grade
    # pages where codes don't sort chronologically).
    last_date = matches.values.map { |m| m[:date] }.compact.max
    candidates = last_date ? matches.select { |_, m| m[:date] == last_date } : matches
    terminal_keys = [candidates.keys.max || matches.keys.max]
  end

  # BFS backward from all terminal matches simultaneously.
  match_round = {}
  queue = terminal_keys.map { |k| [k, 0] }
  until queue.empty?
    key, round = queue.shift
    next if match_round.key?(key)
    match_round[key] = round
    fed_by[key].each { |prev| queue << [prev, round + 1] }
  end

  return [] if match_round.empty?

  # Terminal match winners occupy positions 1..N (sorted by match code).
  placings = terminal_keys.each_with_index.map { |k, i| [i + 1, matches[k][:winner]] }

  max_round = match_round.values.max

  # In a standard single-elimination bracket each round r (counting from the
  # final at 0) should contain exactly 2^r matches. When the player count is
  # not a power of 2, some first-round slots are BYEs — those matches are
  # never played, so they don't appear in match_round. We detect this by
  # checking that every intermediate round follows the 2^r pattern; if so,
  # the shortfall at the deepest round equals the number of BYE slots. Those
  # BYE slots count toward the group position ("made the top 128", not
  # "made the top 103").
  bye_count_deepest = if (0...max_round).all? { |r|
      match_round.count { |_, rv| rv == r } == (1 << r)
    }
    actual = match_round.count { |_, rv| rv == max_round }
    [(1 << max_round) - actual, 0].max
  else
    0
  end

  # Losers from the same round share a position equal to the last slot they
  # collectively occupy: "made the top N" semantics. For example, two
  # semifinal losers in a single-elimination bracket both get position 4
  # rather than 3 and 4 — there is no 3rd place.
  position = terminal_keys.size + 1
  (0..max_round).each do |round|
    round_keys   = match_round.select { |_, r| r == round }.keys.sort
    round_losers = round_keys.map { |k| matches[k][:loser] }.compact
                             .reject { |p| PLACEHOLDER_NAMES.include?(p) }
    bye_extra = round == max_round ? bye_count_deepest : 0
    if round_losers.any?
      group_pos = position + round_losers.size + bye_extra - 1
      round_losers.each { |player| placings << [group_pos, player] }
    end
    position += round_losers.size + bye_extra
  end

  placings.sort_by! { |pos, _| pos }

  # In double-elimination a player can lose then recover, producing duplicate
  # entries. Keep only each player's best (lowest) position.
  seen = {}
  placings.each_with_object([]) do |(pos, player), result|
    next if seen[player]
    seen[player] = true
    result << [pos, player]
  end
end

# ---------------------------------------------------------------------------- double elimination placer

# Returns the match codes (as integers) found in a named HTML section div.
def section_match_codes(html, section_id)
  start_idx = html.index("id=\"#{section_id}\"")
  return [] unless start_idx
  other_sections = %w[draw_main draw_repechage draw_finals].reject { |s| s == section_id }
  end_idx = other_sections.filter_map { |s| html.index("id=\"#{s}\"", start_idx + 1) }.min || html.size
  html[start_idx, end_idx - start_idx].scan(/id="cell_(\d+)_H"/).flatten.map(&:to_i).uniq
end

# Returns { match_code (int) => draw_id (string) } from the embedded JSON.
def parse_match_draw_ids(html)
  json_str = html[/id="dataDraws">(\{.+?\})<\/div>/m, 1]
  return {} unless json_str
  JSON.parse(json_str).each_with_object({}) { |(k, v), h| h[k.to_i] = v[1] }
rescue JSON::ParserError
  {}
end

# Computes placings for double-elimination pages (those with id="draw_repechage").
#
# Repechage draws are grouped into consecutive pairs of equal match count.
# For a pair with N total players per draw (2 × match count):
#   - losers in the first draw of the pair  → position N × 1.5
#   - losers in the second draw of the pair → position N
#
# 1st and 2nd place come from the terminal match in the finals section.
def placings_from_double_elim(matches, html, feeds_winner)
  match_draw_ids  = parse_match_draw_ids(html)
  repechage_codes = section_match_codes(html, 'draw_repechage').to_set
  finals_codes    = section_match_codes(html, 'draw_finals').to_set

  placings = []

  # Finals: winner = 1st, loser = 2nd from the terminal finals match.
  finals_matches = matches.select { |code, _| finals_codes.include?(code) }
  terminal_finals = finals_matches.select { |code, _|
    w = feeds_winner[code]
    w.nil? || !finals_matches.key?(w)
  }
  terminal_finals.each_value do |m|
    placings << [1, m[:winner]] if m[:winner] && !PLACEHOLDER_NAMES.include?(m[:winner])
    placings << [2, m[:loser]]  if m[:loser]  && !PLACEHOLDER_NAMES.include?(m[:loser])
  end

  # Repechage: group matches by draw_id.
  rep_by_draw = Hash.new { |h, k| h[k] = [] }
  matches.each do |code, m|
    next unless repechage_codes.include?(code)
    draw_id = match_draw_ids[code]
    rep_by_draw[draw_id] << m if draw_id
  end

  sorted_draws = rep_by_draw.keys.sort_by(&:to_i)

  # Assign positions by walking draws from best (closest to finals, highest
  # draw_id) to worst (earliest draw, lowest draw_id), tracking a cumulative
  # player count. Each group's position = cumulative after adding that group
  # ("last slot" semantics: e.g. 2 players occupying slots 5-6 both get pos 6).
  # Consecutive draws with the same match count are treated as a pair: the
  # later draw's losers (better players) are assigned first.
  cumulative = placings.size  # 2 after finals section (positions 1 and 2 taken)

  i = sorted_draws.size - 1
  while i >= 0
    draw_b  = sorted_draws[i]
    count_b = rep_by_draw[draw_b].size

    if i - 1 >= 0 && rep_by_draw[sorted_draws[i - 1]].size == count_b
      draw_a   = sorted_draws[i - 1]
      losers_b = rep_by_draw[draw_b].filter_map { |m| m[:loser] unless m[:loser].nil? || PLACEHOLDER_NAMES.include?(m[:loser]) }
      losers_a = rep_by_draw[draw_a].filter_map { |m| m[:loser] unless m[:loser].nil? || PLACEHOLDER_NAMES.include?(m[:loser]) }
      cumulative += losers_b.size
      losers_b.each { |player| placings << [cumulative, player] }
      cumulative += losers_a.size
      losers_a.each { |player| placings << [cumulative, player] }
      i -= 2
    else
      losers = rep_by_draw[draw_b].filter_map { |m| m[:loser] unless m[:loser].nil? || PLACEHOLDER_NAMES.include?(m[:loser]) }
      cumulative += losers.size
      losers.each { |player| placings << [cumulative, player] }
      i -= 1
    end
  end

  placings.sort_by! { |pos, _| pos }

  seen = {}
  placings.each_with_object([]) do |(pos, player), result|
    next if seen[player]
    seen[player] = true
    result << [pos, player]
  end
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

  # Parse bracket feeds (multi-draw double-elimination). Empty for single-draw
  # tournaments; the fallback topology inference handles those.
  feeds_winner, feeds_loser = parse_bracket_feeds(html)

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

  if html.include?('id="draw_repechage"')
    placings_from_double_elim(matches, html, feeds_winner)
  else
    placings_from_matches(matches, feeds_winner: feeds_winner, feeds_loser: feeds_loser)
  end
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
