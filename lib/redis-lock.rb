require "redis"
require "redis-lock/version"

class Redis

  class Lock

    class LockNotAcquired < StandardError
    end

    attr :redis
    attr :key
    attr :okey        # key with redis namespace
    attr :oval
    attr :xkey        # expiration key with redis namespace
    attr :xval
    attr :life, true  # how long we expect to keep this lock locked
    attr :logger, true

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
    end

    def lock( timeout = 1, &block )
      do_lock_with_timeout(timeout) or raise LockNotAcquired.new(key)
      if block then
        begin
          block.call
        ensure
          release_lock
        end
      end
      self
    end

    def unlock
      release_lock
      self
    end

    #
    # queries
    #

    def locked?( now = Time.now.to_i )
      # read both in a transaction in a multi to ensure we have a consistent view
      result = redis.multi do |multi|
        multi.get( okey )
        multi.get( xkey )
      end
      result && result.size == 2 && is_locked?( result[0], result[1], now )
    end

    #
    # internal api
    #

    def do_lock_with_timeout( timeout )
      locked = false
      with_timeout(timeout) { locked = do_lock }
      locked
    end

    # @returns true if locked, false otherwise
    def do_lock( tries = 2 )
      # We need to set both owner and expire at the same time
      # If the existing lock is stale, we delete it and try again once

      loop do
        try_xval = Time.now.to_i + life
        result   = redis.mapped_msetnx okey => oval, xkey => try_xval

        if result == 1 then
          log "do_lock() success"
          @xval = try_xval
          return true

        else
          log "do_lock() failed"
          # consider the possibility that this lock is stale
          tries -= 1
          next if tries > 0 && stale_key?
          return false
        end
      end
    end

    # Only actually deletes it if we own it.
    # There may be strange cases where we fail to delete it, in which case expiration will solve the problem.
    def release_lock( my_owner = oval )
      # Use my_owner = oval to make testing easier.
      with_watch( okey, xkey ) do
        owner = redis.get( okey )
        if owner == my_owner then
          redis.multi do |multi|
            multi.del( okey )
            multi.del( xkey )
          end
        end
      end
    end

    def stale_key?( now = Time.now.to_i )
      # Check if expiration exists and is it stale?
      # If so, delete it.
      # watch() both keys so we can detect if they change while we do this
      # multi() will fail if keys have changed after watch()
      # Thus, we snapshot consistency at the time of watch()
      # Note: inside a watch() we get one and only one multi()
      with_watch( okey, xkey ) do
        owner  = redis.get( okey )
        expire = redis.get( xkey )
        if is_deleteable?( owner, expire, now ) then
          result = redis.multi do |r|
            r.del( okey )
            r.del( xkey )
          end
          # If anything changed then multi() fails and returns nil
          if result && result.size == 2 then
            log "Deleted stale key from #{owner}"
            return true
          end
        end
      end # watch
      # Not stale
      return false
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

    def with_watch( *args, &block )
      # Note: watch() gets cleared by a multi() but it's safe to call unwatch() anyway.
      redis.watch( *args )
      begin
        block.call
      ensure
        redis.unwatch
      end
    end

    # @returns true if the lock exists and is owned by the given owner
    def is_locked?( owner, expiration, now = Time.now.to_i )
      owner == oval && ! is_deleteable?( owner, expiration, now )
    end

    # @returns true if this is a broken or expired lock
    def is_deleteable?( owner, expiration, now = Time.now.to_i )
      expiration = expiration.to_i
      ( owner || expiration > 0 ) && ( ! owner || expiration < now )
    end

    def log( *messages )
      logger.puts "[#{object_id}:#{oval}] #{messages.join(' ')}" if logger
      self
    end

  end # Lock

  # Convenience methods

  def lock( key, timeout = 1, options = {}, &block )
    Lock.new( self, key, options ).lock( timeout, &block )
  end

  def unlock( key )
    Lock( self, key ).unlock
  end

end # Redis
