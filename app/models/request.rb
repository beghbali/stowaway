class Request < ActiveRecord::Base
  STATUSES = %w(outstanding matched fulfilled cancelled timedout)
  validates :status, inclusion: { in: STATUSES }
end
