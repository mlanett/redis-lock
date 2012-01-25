require "helper"

describe Redis::Lock, redis: true do

  before do
    @it = Redis::Lock.new( redis, "test" )
  end

  it "can acquire and release a lock" do
    redis.lock("test") { true }
    expect { redis.lock("test") { true } }.to_not raise_exception
    expect { redis.lock("test") { true } }.to_not raise_exception
  end


  it "can acquire a lock" do
    a = Redis::Lock.new( redis, "test" )
    a.do_lock.should be_true
  end

  it "can release a lock"
  # should test release_lock

  it "can use a timeout" do
    @it.with_timeout(1) { true }.should be_true
    @it.with_timeout(1) { false }.should be_false
    # a few attempts are OK
    results = [ false, false, true ]
    @it.with_timeout(1) { results.shift }.should be_true
    # this is too many attemps
    results = [ false, false, false, false, false, true ]
    @it.with_timeout(1) { results.shift }.should be_false
  end

  it "does not take too long to time out" do
    start = Time.now.to_f
    @it.with_timeout(1) { false }
    time = Time.now.to_f - start
    time.should be_within(0.2).of(1.0)
  end

  it "can detect expired locks" do
    no_owner = nil
    an_owner = "test"
    past     = 1
    present  = 2
    future   = 3
    @it.is_expired?( no_owner, nil,    present ).should be_false # no lock, but should it return true?
    @it.is_expired?( no_owner, future, present ).should be_false # broken
    @it.is_expired?( no_owner, past,   present ).should be_true  # broken
    @it.is_expired?( an_owner, nil,    present ).should be_true  # broken
    @it.is_expired?( an_owner, future, present ).should be_false
    @it.is_expired?( an_owner, past,   present ).should be_true
    # We leave [ present, present ] to be unspecified. It's only a single moment in time, so no worries.
  end

  it "can determine if it is locked" do
    owner   = "self"
    other   = "nope"
    a = Redis::Lock.new( redis, "test", owner: owner )
    past    = 1
    present = 2
    future  = 3
    a.is_locked?( nil,   nil,    present ).should be_false
    a.is_locked?( nil,   future, present ).should be_false
    a.is_locked?( nil,   past,   present ).should be_false
    a.is_locked?( owner, nil,    present ).should be_false
    a.is_locked?( owner, future, present ).should be_true  # the only valid case
    a.is_locked?( owner, past,   present ).should be_false
    a.is_locked?( other, nil,    present ).should be_false
    a.is_locked?( other, future, present ).should be_false
    a.is_locked?( other, past,   present ).should be_false
    # We leave [ present, present ] to be unspecified. It's only a single moment in time, so no worries.
  end


  it "works if you call Lock1.lock and Lock2.lock with the same owner"

end
