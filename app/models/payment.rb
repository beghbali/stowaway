class Payment < ActiveRecord::Base
  belongs_to :request
  belongs_to :receipt, autosave: true

  before_create :generate_receipt


  def generate_receipt
    self.build_receipt(generated_by: 'Stowaway', billed_to: request.rider.full_name, user_id: request.rider.id,
      ride_request_at: request.created_at, pickup_location: request.ride.suggested_pickup_location,
      dropoff_location: request.ride.suggested_dropoff_location, total_amount: self.amount, other_amount: self.fee,
      other_description: I18n.t('models.payment.fee'), distance: request.ride.distance,
      pickup_lat: request.ride.suggested_pickup_lat, pickup_lng: request.ride.suggested_pickup_ng)
  end
end
