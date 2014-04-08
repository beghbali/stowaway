module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body).with_indifferent_access
    end
  end

  module Mocks
    def mock_external_requests
      mock_stowaway_email_creation
      mock_gcm_push_notifications
      mock_push_notifications
      mock_stripe
    end

    def unmock_external_requests
      StripeMock.stop
    end

    def mock_stowaway_email_creation
      stub_request(:post, "http://getstowaway.com/createInbox.php").with(query: hash_including({ nonce: '821222a91eb75f136ea40899'} )).
         to_return(status: 200, body: ->(request) { mock_create_stowaway_email(request).to_json })
    end

    def mock_create_stowaway_email(request)
      username = request.uri.to_s.match(/username=([^&]+)/) && $1
      {
        email:"#{username}@getstowaway.com",
        password: SecureRandom.base64(8)
      }
    end

    def mock_gcm_push_notifications
      stub_request(:post, "https://android.googleapis.com/gcm/send").
               with(body: /.+/,
                    headers: {'Authorization' => 'key=123abc456def', 'Content-Type' => 'application/json'}).
               to_return(status: 200, body: "", headers: {})
    end

    def mock_push_notifications
      mock_apns
    end

    def mock_stripe
      StripeMock.start
    end

    def mock_apns
      allow(APNS).to receive(:send_notification).and_return(true)
    end
  end
end