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

## Background

A lock needs an expected lifetime.
If the owner of a lock disappears (due to machine failure, network failure, process death),
you want the lock to expire and another owner to be able to acquire the lock.
At the same time, the owner of a lock should be able to extend its lifetime.
Thus, you can acquire a lock with a conservative estimate on lifetime, and extend it as necessary,
rather than acquiring the lock with a very long lifetime which will result in long waits in the event of failures.

A lock needs an owner. Redis::Lock defaults to using an owner id of HOSTNAME:PID.

A lock may need more than one attempt to acquire it. Redis::Lock offers a timeout; this defaults to 1 second.
It uses exponential backoff with sleeps so it's fairly safe to use longer timeouts.

## Usage

This gem adds lock() and unlock() to Redis instances.
lock() takes a block and is safer than using lock() and unlock() separately.
lock() takes a key and lifetime and optionally a timeout (otherwise defaulting to 1 second).

redis.lock("test") { do_something }

## Problems

Why do other gems get this wrong?

You need to be able to handle race conditions while acquiring the lock.
You need to be able to handle the owner of the lock failing to release it.
You need to be able to detect stale locks.
You need to handle race conditions while cleaning the stale lock and acquiring a new one.
The code which cleans the stale lock may not be able to assume it gets the new one.
The code which cleans the stale lock must not interfere with a different owner acquiring the lock.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
