class Edition < ApplicationRecord
  belongs_to :tournament
  has_many :placings, dependent: :destroy

  validates :year, :start_date, :end_date, :multiplier, :tournament, presence: true
  validates :multiplier, numericality: { greater_than: 0 }, allow_blank: true

  def name
    "#{year} #{tournament.name}"
  end

  def winner
    sorted_placings.first&.player
  end

  def runner_up
    sorted_placings.second&.player
  end

  private

  def sorted_placings
    placings.order(:position)
  end
end
