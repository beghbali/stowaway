
class API < Grape::API
  prefix 'api'
  format :json
  before do
    Rails.logger.info "REQUEST: #{request.body.read}"
  end

  mount Stowaway::Rides
  mount Stowaway::Users

  get 'c5f443772075576dbdc7' do
    last_commit = `git log --pretty=oneline | head -1 | awk '{print $1}'`
    {commit: last_commit.strip}
  end
end

