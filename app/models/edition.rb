class Edition < ApplicationRecord
  belongs_to :tournament
  has_many :placings

  def name
    "#{year} #{tournament.name}"
  end

  def winner
    sorted_placings[0].player
  end

  def runner_up
    sorted_placings[1].player
  end

  private

  def sorted_placings
    placings.sort_by{|each| each.position}
  end
end
