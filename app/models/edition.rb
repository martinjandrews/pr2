class Edition < ApplicationRecord
  belongs_to :tournament
  has_many :placings, dependent: :destroy

  validates :year, :start_date, :end_date, :tier, :tournament, presence: true
  validates :tier, numericality: { greater_than: 0 }, allow_blank: true

  TIER_MULTIPLIER = {
    1 => 4,
    2 => 3,
    3 => 2,
    4 => 1
  }.freeze

  def name
    "#{year} #{tournament.name}"
  end

  def winner
    sorted_placings.first&.player
  end

  def runner_up
    sorted_placings.second&.player
  end

  def multiplier
    TIER_MULTIPLIER[tier] || TIER_MULTIPLIER.values.min
  end

  private

  def sorted_placings
    placings.order(:position)
  end
end
