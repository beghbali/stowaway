class Request < ActiveRecord::Base
  STATUSES = %w(outstanding matched fulfilled cancelled timedout)
  DEVICE_TYPES = %w(ios android)
  validates :status, inclusion: { in: STATUSES }
  validates :device_type, inclusion: { in: DEVICE_TYPES }
end
