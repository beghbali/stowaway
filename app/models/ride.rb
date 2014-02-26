class Ride < ActiveRecord::Base
  include Notify::Notifier
  CAPACITY = 4

  has_many :requests
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'

  def has_captain?
    false #reimplement when implementing captain bit
  end

  def riders
    self.requests
  end

  def as_json(options = {})
    { requests: self.requests.reduce(Hash.new([])){|ride_h, req| ride_h[:requests] << req.as_json(format: :notification) } }
  end
end