require "redis"
require "redis-lock/version"

class Redis

  class Lock

    class LockNotAcquired < StandardError
    end

    attr :okey        # key with redis namespace
    attr :oval
    attr :xkey        # expiration key with redis namespace
    attr :xval
    attr :life        # how long we expect to keep this lock locked
    attr :locked

    # @param redis is a Redis instance
    # @param key is a unique string identifying the object to lock, e.g. "user-1"
    # @param options[:life] may be set, but defaults to 1 minute
    # @param options[:owner] may be set, but defaults to HOSTNAME:PID
    def initialize( redis, key, options = {} )
      @redis  = redis
      @key    = key
      @okey   = "lock:owner:#{key}"
      @oval   = options[:owner] || "#{`hostname`.strip}:#{Process.pid}"
      @xkey   = "lock:expire:#{key}"
      @life   = options[:life] || 60
      @locked = false
    end

    def lock( timeout = 1, &block )
      acquire_lock(timeout) or raise LockNotAcquired.new(key)
      if block then
        begin
          block.call
        ensure
          release_lock
        end
      end
    end

    def unlock
      release_lock
    end

    def acquire_lock( timeout )
      @locked = false
      with_timeout(timeout) { successfully_locked_key? }
      @locked
    end

    # @returns true if locked, false otherwise
    def successfully_locked_key?( tries = 2 )

      # We need to set both owner and expire at the same time
      # If the existing lock is stale, we try again once

      loop do
        try_xval = Time.now.to_i + life
        result   = redis.msetnx okey, oval, xkey, try_xval

        if result == 1 then
          log "successfully_locked_key?() success"
          @xval   = try_xval
          @locked = true
          return true

        else
          log "successfully_locked_key?() failed"
          # consider the possibility that this lock is stale
          tries -= 1
          next if tries > 0 && stale_key?
          return false
        end
      end
    end

    def stale_key?
      false
    end

    def release_lock
      redis.del okey
      redis.del xkey
      true
    end

    # Calls block until it returns true or times out. Uses exponential backoff.
    # @param block should return true if successful, false otherwise
    # @returns true if successful, false otherwise
    def with_timeout( timeout, &block )
      expire = Time.now + timeout.to_f
      sleepy = 0.125
      # this looks inelegant compared to while Time.now < expire, but does not oversleep
      loop do
        return true if block.call
        log "Timeout" and return false if Time.now + sleepy > expire
        sleep(sleepy)
        sleepy *= 2
      end
    end

    def log( *messages )
      # STDERR.puts "[#{object_id}] #{messages.join(' ')}"
      true
    end

  end # Lock

  # Convenience methods

  def lock( key, timeout = 1, &block )
    Lock.new( self, key ).lock( timeout, &block )
  end

  def unlock( key )
    Lock( self, key ).unlock
  end

end # Redis
