# Redis::Lock

[![Build Status](https://secure.travis-ci.org/langalex/redis-lock.png?branch=master)](http://travis-ci.org/langalex/redis-lock)


This gem implements a pessimistic lock using Redis.
It correctly handles timeouts and vanishing lock owners (such as machine failures)

This uses setnx, but not the setnx algorithm described in the redis cookbook, which is not robust.

## Installation

Add this line to your application's Gemfile:

    gem 'mlanett-redis-lock', require: 'redis-lock'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mlanett-redis-lock

## Background

A lock needs an expected lifetime.
If the owner of a lock disappears (due to machine failure, network failure, process death),
you want the lock to expire and another owner to be able to acquire the lock.
At the same time, the owner of a lock should be able to extend its lifetime.
Thus, you can acquire a lock with a conservative estimate on lifetime, and extend it as necessary,
rather than acquiring the lock with a very long lifetime which will result in long waits in the event of failures.

A lock needs an owner. Redis::Lock defaults to using an owner id of HOSTNAME:PID.

A lock may need more than one attempt to acquire it. Redis::Lock offers an acquisition timeout; this defaults to 10 seconds.

There are two lock methods: Redis#lock, which is more convenient, and Redis::Lock#lock.
Notice there are two timeouts: the lock's lifetime (```:life``` option) and the acquisition timeout, which is less important.
The acquisition timeout is set via the :acquire option to Redis#lock or passed directly to Redis::Lock#lock.

## Usage

This gem adds ```lock()``` and ```unlock()``` to Redis instances.

```lock()``` takes a block and is safer than using ```lock()``` and ```unlock()``` separately.
```lock()``` takes a key and lifetime and optionally an acquisition timeout (defaulting to 10 seconds).

```ruby
redis.lock("test") { |lock| do_something }

redis.lock("test", life: 2*60, acquire: 2) do |lock|
  array.each do |entry|
    do_something(entry)
    lock.extend_life(60)
  end
end
```

## Goals

I wrote this when noticing that other lock gems were using non-robust approaches.

You need to be able to handle race conditions while acquiring the lock.
You need to be able to handle the owner of the lock failing to release it.
You need to be able to detect stale locks.
You need to handle race conditions while cleaning the stale lock and acquiring a new one.
The code which cleans the stale lock may not be able to assume it gets the new one.
The code which cleans the stale lock must not interfere with a different owner acquiring the lock.

## Contributors

Alexander Lang (langalex), Jonathan Hyman (jonhyman), Jamie Cobbett (jamiecobbett), and Ravil Bayramgalin (brainopia) have contributed to Redis Lock.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
