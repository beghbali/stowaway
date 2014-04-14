class ReconcileReceiptsJob
  @queue = :reconcile_receipts_queue

  def self.perform(ride_public_id)
    ride = Ride.find_by_public_id(ride_public_id)
    raise "ride not found: #{ride_public_id}" if ride.nil?

    Ride.transaction do
      unless ride.reconciled?
        ride.reconcile_receipt
        verify_in = Time.now < (ride.created_at + 1.hour) ? 5.minutes : 3.hours
        Resque.enqueue_in(5.minutes, ReconcileReceiptsJob, ride.public_id) unless Time.now > (ride.created_at + 28.hours)
      end
    end
  end
end