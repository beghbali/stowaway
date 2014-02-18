class Request < ActiveRecord::Base
  include PublicId
  has_public_id

  STATUSES = %w(outstanding matched fulfilled cancelled timedout)
  validates :status, inclusion: { in: STATUSES }

  def as_json(options = {})
    super(except: [:id, :user_id])
  end
end
