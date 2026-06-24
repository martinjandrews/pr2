class Tournament < ApplicationRecord
  has_many :editions

  validates :name, presence: true
end
