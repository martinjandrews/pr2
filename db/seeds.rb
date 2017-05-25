require 'csv'

albury = Tournament.find_by(name: 'Albury/Wodonga')
anzac = Tournament.find_by(name: 'ANZAC Open')
aus_open = Tournament.find_by(name: 'Australian Open Singles')
berri = Tournament.find_by(name: 'Berri Resort Hotel Open')
big_guns = Tournament.find_by(name: 'Big Guns')
darwin = Tournament.find_by(name: 'Darwin Open')
empire = Tournament.find_by(name: 'Empire Classic')
geelong = Tournament.find_by(name: 'Geelong Open')
lp = Tournament.find_by(name: 'LP Cues')
wa = Tournament.find_by(name: 'Western National')

darwin_2017 = Edition.find_by(year: 2017, tournament: darwin)
darwin_2016 = Edition.find_by(year: 2016, tournament: darwin)
darwin_2015 = Edition.find_by(year: 2015, tournament: darwin)

anzac_2017 = Edition.find_by(year: 2017, tournament: anzac)
anzac_2016 = Edition.find_by(year: 2016, tournament: anzac)
anzac_2015 = Edition.find_by(year: 2015, tournament: anzac)

lp_2017 = Edition.find_by(year: 2017, tournament: lp)
lp_2016 = Edition.find_by(year: 2016, tournament: lp)
lp_2015 = Edition.find_by(year: 2015, tournament: lp)

big_guns_2017 = Edition.find_by(year: 2017, tournament: big_guns)
big_guns_2016 = Edition.find_by(year: 2016, tournament: big_guns)
big_guns_2015 = Edition.find_by(year: 2015, tournament: big_guns)

albury_2017 = Edition.find_by(year: 2017, tournament: albury)
albury_2016 = Edition.find_by(year: 2016, tournament: albury)
albury_2015 = Edition.find_by(year: 2015, tournament: albury)

geelong_2017 = Edition.find_by(year: 2017, tournament: geelong)
geelong_2016 = Edition.find_by(year: 2016, tournament: geelong)
geelong_2015 = Edition.find_by(year: 2015, tournament: geelong)

aus_open_2016 = Edition.find_by(year: 2016, tournament: aus_open)
aus_open_2015 = Edition.find_by(year: 2015, tournament: aus_open)
aus_open_2014 = Edition.find_by(year: 2014, tournament: aus_open)

empire_2016 = Edition.find_by(year: 2016, tournament: empire)
empire_2015 = Edition.find_by(year: 2015, tournament: empire)

berri_2016 = Edition.find_by(year: 2016, tournament: berri)
berri_2015 = Edition.find_by(year: 2015, tournament: berri)

wa_2016 = Edition.find_by(year: 2016, tournament: wa)
wa_2015 = Edition.find_by(year: 2015, tournament: wa)

#
# Player.create(first_name: 'Aaron', last_name: 'Mahoney')
# Player.create(first_name: 'Aaron', last_name: 'Tretheway')


CSV.foreach("rankings.csv") do |row|
  names = row[0].split(' ', 2)
  first_name = names[0]
  last_name = names[1]
  player = Player.find_by(first_name: first_name, last_name: last_name)

  Placing.create(position: row[1].to_i, edition: darwin_2017, player: player) if row[1]
  Placing.create(position: row[2].to_i, edition: anzac_2017, player: player) if row[2]
  Placing.create(position: row[3].to_i, edition: lp_2017, player: player) if row[3]
  Placing.create(position: row[4].to_i, edition: big_guns_2017, player: player) if row[4]
  Placing.create(position: row[5].to_i, edition: albury_2017, player: player) if row[5]
  Placing.create(position: row[6].to_i, edition: geelong_2017, player: player) if row[6]
  Placing.create(position: row[7].to_i, edition: aus_open_2016, player: player) if row[7]
  Placing.create(position: row[8].to_i, edition: empire_2016, player: player) if row[8]
  Placing.create(position: row[9].to_i, edition: berri_2016, player: player) if row[9]
  Placing.create(position: row[10].to_i, edition: wa_2016, player: player) if row[10]
  Placing.create(position: row[11].to_i, edition: darwin_2016, player: player) if row[11]
  Placing.create(position: row[12].to_i, edition: anzac_2016, player: player) if row[12]
  Placing.create(position: row[13].to_i, edition: lp_2016, player: player) if row[13]
  Placing.create(position: row[14].to_i, edition: big_guns_2016, player: player) if row[14]
  Placing.create(position: row[15].to_i, edition: albury_2016, player: player) if row[15]
  Placing.create(position: row[16].to_i, edition: geelong_2016, player: player) if row[16]
  Placing.create(position: row[17].to_i, edition: aus_open_2015, player: player) if row[17]
  Placing.create(position: row[18].to_i, edition: empire_2015, player: player) if row[18]
  Placing.create(position: row[19].to_i, edition: berri_2015, player: player) if row[19]
  Placing.create(position: row[20].to_i, edition: wa_2015, player: player) if row[20]
  Placing.create(position: row[21].to_i, edition: darwin_2015, player: player) if row[21]
  Placing.create(position: row[22].to_i, edition: anzac_2015, player: player) if row[22]
  Placing.create(position: row[23].to_i, edition: lp_2015, player: player) if row[23]
  Placing.create(position: row[24].to_i, edition: big_guns_2015, player: player) if row[24]
  Placing.create(position: row[25].to_i, edition: albury_2015, player: player) if row[25]
  Placing.create(position: row[26].to_i, edition: geelong_2015, player: player) if row[26]
  Placing.create(position: row[27].to_i, edition: aus_open_2014, player: player) if row[27]
end
