class ReconcileReceiptsJob
  @queue = :reconcile_receipts_queue

  def self.perform(user_public_id)
    user = User.find_by_public_id(user_public_id)
    raise "user not found: #{user_public_id}" if user.nil?

    User.transaction do
      user.reconcile_ride_receipts
    end
  end
end