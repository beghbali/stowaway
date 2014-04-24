
class API < Grape::API
  prefix 'api'
  format :json

  before do
    Rails.logger.info "REQUEST: #{params.to_hash.except("route_info")}"
  end

  mount Stowaway::Rides
  mount Stowaway::Users

  resource :admin do
    http_basic do |email, password|
      email == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
    end

    get 'c5f443772075576dbdc7' do
      last_commit = `git log --pretty=oneline | head -1 | awk '{print $1}'`
      {commit: last_commit.strip}
    end
  end
end

