class Ride < ActiveRecord::Base
  include Notify::Notifier
  include PublicId

  has_public_id
  CAPACITY = 4

  has_many :requests
  has_many :riders, through: :requests, source: :user
  has_many :stowaways, -> { stowaways }, class_name: 'Request'
  has_one :captain, -> { captains }, class_name: 'Request'

  before_create :generate_location_channel

  def has_captain?
    false #reimplement when implementing captain bit
  end

  def as_json(options = {})
    reqs = options[:requests] || self.requests
    super(only: [:location_channel, :public_id]).merge(requests: reqs.map{|req| req.as_json(format: :notification) })
  end

  def generate_location_channel
    self.location_channel = "#{SecureRandom.hex(10)}"
  end
end