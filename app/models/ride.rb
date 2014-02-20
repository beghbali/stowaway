class Ride < ActiveRecord::Base
  CAPACITY = 4

  has_many :requests
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'

  def has_captain?
    false #reimplement when implementing captain bit
  end
end