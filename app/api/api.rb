
class API < Grape::API
	prefix 'api'
	mount Stowaway::Rides
  mount Stowaway::Users
end

