require "redis"
require "redis-lock/version"

class Redis

  class Lock
    # @param redis is a Redis instance
    # @param key is a unique string identifying the object to lock, e.g. "user-1"
    def initialize( redis, key )
      @redis  = redis
      @key    = key
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
        true
    end

    def release_lock
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
