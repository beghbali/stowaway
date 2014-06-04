class ReconcileReceiptsJob
  @queue = :reconcile_receipt
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(ride_id)
    ride = Ride.find(ride_id)
    raise "ride not found: #{ride_id}" if ride.nil?

    Ride.transaction do
      unless ride.reconciled?
        ride.reconcile_receipt
        verify_in = Time.now < (ride.created_at + 1.hour) ? 5.minutes : 3.hours
        Resque.enqueue_in(5.minutes, ReconcileReceiptsJob, ride.id) unless Time.now > (ride.created_at + 28.hours)
      end
    end
  end
end