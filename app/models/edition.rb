class Edition < ApplicationRecord
  belongs_to :tournament
  has_many :placings

  def name
    "#{year} #{tournament.name}"
  end
end
