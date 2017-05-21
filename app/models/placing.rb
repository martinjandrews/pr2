class Placing < ApplicationRecord
  belongs_to :edition
  belongs_to :player
end
