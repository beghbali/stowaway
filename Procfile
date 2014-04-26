autocheckin: bundle exec rake environment resque:work QUEUE=autocheckin VERBOSE=true
emails: bundle exec rake environment resque:work QUEUE=email_parser VERBOSE=true
receipts: bundle exec rake environment resque:work QUEUE=reconcile_receipts VERBOSE=true
closer: bundle exec rake environment resque:work QUEUE=close_ride VERBOSE=true