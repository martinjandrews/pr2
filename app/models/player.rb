class Player < ApplicationRecord
  has_many :placings

  validates :first_name, :last_name, presence: true

  def name
    "#{first_name} #{last_name}"
  end
end
