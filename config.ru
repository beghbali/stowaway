# This file is used by Rack-based servers to start the application.
require 'resque/server'
Resque::Server.use Rack::Auth::Basic do |username, password|
  username == ENV['RESQUE_WEB_HTTP_BASIC_AUTH_USER'] && password == ENV['RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD']
end
require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application
