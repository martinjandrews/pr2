class Edition < ApplicationRecord
  belongs_to :tournament

  def name
    "#{year} #{tournament.name}"
  end
end
