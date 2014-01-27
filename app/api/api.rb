
class API < Grape::API
  prefix 'api'
  before do
    Rails.logger.info "REQUEST: #{request.body.read}"
  end

  mount Stowaway::Rides
  mount Stowaway::Users
end

