require "ostruct"
require "redis"
require "redis-lock/version"

class Redis

  ###
  # Set/release/extend locks on a single redis instance.
  # See http://redis.io/commands/set
  #
  class Lock

    class LockNotAcquired < StandardError
    end

    @@config = OpenStruct.new(
      default_timeout: 10,
      default_life: 60,
      default_sleep: 125
    )

    attr_reader :redis
    attr_reader :key
    attr_reader :owner
    attr_accessor :life     # how long we expect to keep this lock locked
    attr_accessor :logger

    HOST = `hostname`.strip
    RELEASE_SCRIPT = <<EOS
if redis.call("get",KEYS[1]) == ARGV[1]
then
    return redis.call("del",KEYS[1])
else
    return 0
end
EOS

    EXTEND_SCRIPT = <<EOS
if redis.call("get",KEYS[1]) == ARGV[1]
then
    return redis.call("expire",KEYS[1],tonumber(ARGV[2]))
else
    return 0
end
EOS

    # @param redis is a Redis instance
    # @param key is a unique string identifying the object to lock, e.g. "user-1"
    # @param options[:life] should be set, but defaults to 1 minute
    # @param options[:owner] may be set, but defaults to HOSTNAME:PID
    # @param options[:sleep] is used when trying to acquire the lock; milliseconds; defaults to 125.
    def initialize( redis, key, options = {} )
      check_keys( options, :owner, :life, :sleep )
      @redis  = redis
      @key    = "lock:#{key}"
      @owner  = options[:owner] || "#{HOST}:#{Process.pid}"
      @life   = options[:life] || @@config.default_life
      @sleep_in_ms = options[:sleep] || @@config.default_sleep
    end

    # @param acquisition_timeout defaults to 10 seconds and can be used to determine how long to wait for a lock.
    def lock( acquisition_timeout = nil, &block )
      acquisition_timeout = @@config.default_timeout if acquisition_timeout.nil?
      do_lock_with_timeout(acquisition_timeout) or raise LockNotAcquired.new(key)
      if block then
        begin
          result = (block.arity == 1) ? block.call(self) : block.call
        ensure
          release_lock
        end
      end
      result
    end

    def extend_life( new_life )
      do_extend( new_life ) or raise LockNotAcquired.new(key)
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
      redis.get(key) == owner
    end

    #
    # internal api
    #

    private
    def do_lock_with_timeout( acquisition_timeout )
      locked = false
      with_timeout(acquisition_timeout) { locked = do_lock }
      locked
    end

    # @returns true if locked, false otherwise
    def do_lock
      !!redis.set(key, owner, nx: true, px: (life * 1000).to_i)
    end

    def do_extend( new_life, my_owner = owner )
      !!redis.eval_and_cache(
        EXTEND_SCRIPT, keys: [key], argv: [my_owner, new_life])
    end

    # Only actually deletes it if we own it.
    # There may be strange cases where we fail to delete it, in which case expiration will solve the problem.
    def release_lock( my_owner = owner )
      !!redis.eval_and_cache(RELEASE_SCRIPT, keys: [key], argv: [my_owner])
    end

    # Calls block until it returns true or times out.
    # @param block should return true if successful, false otherwise
    # @returns true if successful, false otherwise
    # Note: at one time I thought of using a backoff strategy, but don't think that's important now.
    def with_timeout( timeout, &block )
      expire = Time.now + timeout.to_f
      sleepy = @sleep_in_ms / 1000.to_f()
      # this looks inelegant compared to while Time.now < expire, but does not oversleep
      loop do
        return true if block.call
        log :debug, "Timeout for #{@key}" and return false if Time.now + sleepy > expire
        sleep(sleepy)
        # might like a different strategy, but general goal is not use 100% cpu while contending for a lock.
      end
    end

    def log( level, *messages )
      if logger then
        logger.send(level) { "[#{Time.now.strftime "%Y%m%d%H%M%S"} #{oval}] #{messages.join(' ')}" }
      end
      self
    end

    def check_keys( set, *keys )
      extra = set.keys - keys
      raise "Unknown Option #{extra.first}" if extra.size > 0
    end

    def self.config
      @@config
    end
  end # Lock

  # Convenience methods

  # @param key is a unique string identifying the object to lock, e.g. "user-1"
  # @options are as specified for Redis::Lock#lock (including :life)
  # @param options[:life] should be set, but defaults to 1 minute
  # @param options[:owner] may be set, but defaults to HOSTNAME:PID
  # @param options[:sleep] is used when trying to acquire the lock; milliseconds; defaults to 125.
  # @param options[:acquire] defaults to 10 seconds and can be used to determine how long to wait for a lock.
  def lock( key, options = {}, &block )
    acquire = options.delete(:acquire) || 10
    Redis::Lock.new( self, key, options ).lock( acquire, &block )
  end

  def unlock( key )
    Redis::Lock.new( self, key ).unlock
  end

  def eval_and_cache( script, options = {} )
    @script_cache ||= {}
    if @script_cache.include?(script)
      evalsha(@script_cache[script], keys: options[:keys], argv: options[:argv])
    else
      result = eval(script, keys: options[:keys], argv: options[:argv])
      @script_cache = Digest::SHA1.hexdigest(script)
      result
    end
  end
end # Redis
