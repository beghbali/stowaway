class ReceiptMailer

  def captain_ride_receipt(captain_id, ride_id)
    @rider = User.find(captain_id)
    @ride = Ride.find(ride_id)
  end

  def stowaway_ride_receipt
  end
end