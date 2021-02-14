# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

task :export do
  header = "Name"
  Edition.all.each do |edition|
    header += ", #{edition.name}"
  end
  puts header
  Player.all.each do |player|
    output = "#{player.first_name} #{player.last_name}"
    Edition.all.each do |edition|
      placing = Placing.find_by edition: edition.id, player: player.id
      result = placing ? ", #{placing.position}" : ", "
      output += result
    end
    puts output
  end
end
