class Request < ActiveRecord::Base
  STATUSES = %w(outstanding matched fulfilled cancelled timedout)
<<<<<<< HEAD
  DEVICE_TYPES = %w(ios android)
  validates :status, inclusion: { in: STATUSES }
  validates :device_type, inclusion: { in: DEVICE_TYPES }
=======
  validates :status, inclusion: { in: STATUSES }
>>>>>>> parent of dc396ca... Merge pull request #4 from TrexMarketing/feature/65420424/match-requests
end
