require "redis"
require "redis-lock/version"

class Redis

  class Lock

    class LockNotAcquired < StandardError
    end

    attr :life        # how long we expect to keep this lock locked
    # @param redis is a Redis instance
    # @param key is a unique string identifying the object to lock, e.g. "user-1"
    def initialize( redis, key )
    # @param options[:life] may be set, but defaults to 1 minute
      @redis  = redis
      @key    = key
      @life   = options[:life] || 60
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
      with_timeout(timeout) do
        true
      end
    end

    def release_lock
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
