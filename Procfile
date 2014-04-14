autocheckin: bundle exec rake environment resque:work QUEUE=checkin_queue VERBOSE=true
emails: bundle exec rake environment resque:work QUEUE=parse_emails_queue VERBOSE=true
receipts: bundle exec rake environment resque:work QUEUE=reconcile_receipts_queue VERBOSE=true