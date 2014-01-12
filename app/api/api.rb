
class API < Grape::API
	prefix 'api'
	mount Stowaway::Ride
end

