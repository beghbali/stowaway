  web: bundle exec rails server
  redis: redis-server /usr/local/etc/redis.conf
  worker: bundle exec rake environment resque:work QUEUE=* VERBOSE=true
