class Placing < ApplicationRecord
  belongs_to :edition
  belongs_to :player

  validates :position, :edition, :player, presence: true
  validates :player_id, uniqueness: { scope: :edition_id }

  def name
    return 'Winner'    if position == 1
    return 'Runner up' if position == 2
    "Top #{position}"
  end
end
