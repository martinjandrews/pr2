class Player < ApplicationRecord
  has_many :placings

  def name
    "#{first_name} #{last_name}"
  end
end
