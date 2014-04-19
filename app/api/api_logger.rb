class ApiLogger < Grape::Middleware::Base

  def before
    Rails.logger.info "[api] REQUEST: #{request_log_data.to_json}"
  end

  private

  def request_log_data
    rack_input = env["rack.input"].gets

    if rack_input.present?
      rack_input = rack_input.gsub("&","%26")
      params_data = Rack::Utils.parse_query(rack_input, "&")
    else
      params_data = nil
    end
    request_data = {
      method: env['REQUEST_METHOD'],
      path:   env['PATH_INFO'],
      params: params_data
    }
    request_data
  end

  def response_log_data
    {
      description: env['api.endpoint'].options[:route_options][:description],
      source_file: env['api.endpoint'].block.source_location[0][(Rails.root.to_s.length+1)..-1],
      source_line: env['api.endpoint'].block.source_location[1]
    }
  end

end