autocheckin: bundle exec rake environment resque:work QUEUE=autocheckin VERBOSE=true
close_ride: bundle exec rake environment resque:work QUEUE=close_ride VERBOSE=true
finalize: bundle exec rake environment resque:work QUEUE=finalize VERBOSE=true
initiate: bundle exec rake environment resque:work QUEUE=initiate VERBOSE=true
notifications: bundle exec rake environment resque:work QUEUE=notify_neighbor VERBOSE=true
email_parser: bundle exec rake environment resque:work QUEUE=email_parser VERBOSE=true
reconcile_receipt: bundle exec rake environment resque:work QUEUE=reconcile_receipt VERBOSE=true
scheduler: bundle exec rake environment resque:scheduler
