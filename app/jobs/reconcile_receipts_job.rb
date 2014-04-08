class ReconcileReceiptsJob
  @queue = :reconcile_receipts_queue

  def self.perform(ride_public_id)
    ride = Ride.find_by_public_id(ride_public_id)
    raise "ride not found: #{ride_public_id}" if ride.nil?

    Ride.transaction do
      ride.reconcile_receipt
      Resque.enqueue_in(5.minutes, ReconcileReceiptsJob, ride.public_id) unless ride.reconciled? && Time.now < (ride.created_at + 1.hour)
    end
  end
end