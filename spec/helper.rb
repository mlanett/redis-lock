# -*- encoding: utf-8 -*-

require "bundler/setup"       # set up gem paths
#require "ruby-debug"          # because sometimes you need it

require "simplecov"           # code coverage
SimpleCov.start               # must be loaded before our own code

require "redis-lock"          # load this gem
require "support/redis"       # simple helpers for testing

RSpec.configure do |spec|
  # @see https://www.relishapp.com/rspec/rspec-core/docs/helper-methods/define-helper-methods-in-a-module
  spec.include RedisClient, redis: true

  # nuke the Redis database around each run
  # @see https://www.relishapp.com/rspec/rspec-core/docs/hooks/around-hooks
  spec.around( :each, redis: true ) do |example|
    with_clean_redis { example.run }
  end
end
