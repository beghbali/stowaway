class Payment < ActiveRecord::Base
  belongs_to :request
  has_one :receipt, autosave: true

  before_create :generate_receipt

  def generate_receipt
    self.build_receipt(generated_by: 'Stowaway', billed_to: request.rider.email, user_id: request.rider.id,
      ride_requested_at: request.created_at, pickup_location: request.ride.suggested_pickup_address,
      dropoff_location: request.ride.suggested_dropoff_address, total_amount: self.amount, other_amount: self.fee,
      other_description: I18n.t('models.payment.fee'), distance: request.ride.distance,
      pickup_lat: request.ride.suggested_pickup_lat, pickup_lng: request.ride.suggested_pickup_lng)
  end
end
