class Ride < ActiveRecord::Base
  include Notify::Notifier
  CAPACITY = 4

  has_many :requests
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'

  before_create :generate_location_channel

  def has_captain?
    false #reimplement when implementing captain bit
  end

  def riders
    self.requests
  end

  def as_json(options = {})
    super(only: [:location_channel]).merge(requests: self.requests.map{ |request| request.as_json(format: :notification) })
  end

  def generate_location_channel
    self.location_channel = "#{SecureRandom.hex(10)}"
  end
end