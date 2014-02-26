APNS.host = ENV['APNS_HOST'] || 'gateway.sandbox.push.apple.com'
APNS.port = 2195
APNS.pem = ENV['APNS_PEM']
APNS.pass = ENV['APNS_PEM_PASS']

GCM.host = ENV['GCM_HOST'] || 'https://android.googleapis.com/gcm/send'
GCM.format = :json
GCM.key = ENV['GCM_KEY'] || "123abc456def"