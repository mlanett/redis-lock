# Redis::Lock

This gem implements a pessimistic lock using Redis.
It correctly handles timeouts and vanishing lock owners (such as machine failures)

## Installation

Add this line to your application's Gemfile:

    gem 'redis-lock'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-lock

## Usage

This gem adds lock() and unlock() to Redis instances.
lock() takes a block and is safer than using lock() and unlock() separately.
lock() takes a key and optionally a timeout (otherwise defaulting to 1 second).

redis.lock("test") { do_something }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
