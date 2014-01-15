module Stowaway
  class Rides < Grape::API
    version :v1
    format :json

    desc "handles ride requests"

    resource :rides do
      namespace :admin do
        get 'status' do
          "Arrr"
        end
      end
    end

  end
end