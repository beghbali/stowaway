require 'resque/tasks'
require 'resque'
require 'resque_scheduler'
require 'resque/scheduler'
require 'resque_scheduler/server'
require 'resque_scheduler/tasks'

task 'resque:setup' => :environment
