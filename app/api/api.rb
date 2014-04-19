
class API < Grape::API
  prefix 'api'
  format :json

  mount Stowaway::Rides
  mount Stowaway::Users

  use ApiLogger

  get 'c5f443772075576dbdc7' do
    last_commit = `git log --pretty=oneline | head -1 | awk '{print $1}'`
    {commit: last_commit.strip}
  end
end

