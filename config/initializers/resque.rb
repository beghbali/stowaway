Resque.redis = Redis.new(host: ENV['REDIS_HOST'] || "localhost", port: ENV['REDIS_PORT'] || 6379, :password => ENV['REDIS_PASSWORD'])
Resque.logger = Logger.new
Resque.logger.level = Logger::DEBUG
