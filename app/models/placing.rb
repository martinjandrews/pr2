class Placing < ApplicationRecord
  belongs_to :edition
  belongs_to :player

  def name
    name = "Top #{position}"
    name = 'Runner up' if position == 2
    name = 'Winner' if position == 1
    name
  end
end
