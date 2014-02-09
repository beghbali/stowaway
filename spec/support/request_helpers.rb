module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body).with_indifferent_access
    end
  end

  module Mocks
    def mock_external_requests
      mock_stowaway_email_creation
    end

    def mock_stowaway_email_creation
      stub_request(:post, "http://stow.mailbsend.com/createInbox.php").with(query: hash_including({ nonce: '821222a91eb75f136ea40899'} )).
         to_return(status: 200, body: ->(request) { mock_create_stowaway_email(request).to_json })
    end

    def mock_create_stowaway_email(request)
      username = request.uri.to_s.match(/username=([^&]+)/) && $1
      {
        email:"#{username}@getstowaway.com",
        password: SecureRandom.base64(8)
      }
    end
  end
end