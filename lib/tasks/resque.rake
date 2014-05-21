require 'resque/tasks'
require 'resque'
require 'resque_scheduler'
require 'resque/scheduler'
require 'resque_scheduler/server'

task 'resque:setup' => :environment
