require "helper"

describe Redis::Lock, redis: true do

  before do
    @a_owner = "first"
    @b_owner = "second"
    @a  = Redis::Lock.new( redis, "one", owner: @a_owner )
    @b1 = Redis::Lock.new( redis, "one", owner: @b_owner )
    @b2 = Redis::Lock.new( redis, "two", owner: @b_owner )
  end

  it "can acquire and release a lock" do
    redis.lock("key") { true }
    expect { redis.lock("key") { true } }.to_not raise_exception
    expect { redis.lock("key") { true } }.to_not raise_exception
  end

  it "can lock two different items at the same time" do
    @b1.lock do
      expect { @b2.lock.unlock }.to_not raise_exception
      @b1.should be_locked
    end
  end


  it "can acquire a lock" do
    @a.do_lock.should be_true
  end

  it "can release a lock" do
    @a.lock
    @a.release_lock
  end

  it "can use a timeout" do
    @a.with_timeout(1) { true }.should be_true
    @a.with_timeout(1) { false }.should be_false
    # a few attempts are OK
    results = [ false, false, true ]
    @a.with_timeout(1) { results.shift }.should be_true
    # this is too many attemps
    results = [ false, false, false, false, false, true ]
    @a.with_timeout(1) { results.shift }.should be_false
  end

  it "does not take too long to time out" do
    start = Time.now.to_f
    @a.with_timeout(1) { false }
    time = Time.now.to_f - start
    time.should be_within(0.2).of(1.0)
  end

  it "can detect expired locks if they exist in any form (even if broken) and are not current" do
    no_owner = nil
    an_owner = "self"
    it       = Redis::Lock.new( redis, "key", owner: an_owner )
    past     = 1
    present  = 2
    future   = 3
    it.is_expired?( no_owner, nil,    present ).should be_false # no lock
    it.is_expired?( no_owner, future, present ).should be_false # broken
    it.is_expired?( no_owner, past,   present ).should be_true  # broken
    it.is_expired?( an_owner, nil,    present ).should be_true  # broken
    it.is_expired?( an_owner, future, present ).should be_false
    it.is_expired?( an_owner, past,   present ).should be_true
    # We leave [ present, present ] to be unspecified.
  end

  it "can determine if it is locked" do
    owner   = "self"
    other   = "nope"
    it      = Redis::Lock.new( redis, "key", owner: owner )
    past    = 1
    present = 2
    future  = 3
    it.is_locked?( nil,   nil,    present ).should be_false
    it.is_locked?( nil,   future, present ).should be_false
    it.is_locked?( nil,   past,   present ).should be_false
    it.is_locked?( owner, nil,    present ).should be_false
    it.is_locked?( owner, future, present ).should be_true  # the only valid case
    it.is_locked?( owner, past,   present ).should be_false
    it.is_locked?( other, nil,    present ).should be_false
    it.is_locked?( other, future, present ).should be_false
    it.is_locked?( other, past,   present ).should be_false
    # We leave [ present, present ] to be unspecified.
  end


  it "works if you call Lock1.lock and Lock2.lock with the same owner"

end
