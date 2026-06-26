class Player < ApplicationRecord
  has_many :placings

  validates :first_name, :last_name, presence: true

  def name
    "#{first_name} #{last_name}"
  end

  def merge_into(other)
    placings.each do |placing|
      next if Placing.exists?(edition: placing.edition, player: other)
      placing.update!(player: other)
    end
    destroy
  end
end
