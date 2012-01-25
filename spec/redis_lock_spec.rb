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
    @a.lock do
      @a.should be_locked
      expect { @b1.lock.unlock }.to raise_exception
    end
    @a.should_not be_locked
    expect { @b1.lock.unlock }.to_not raise_exception
  end

  it "can lock two different items at the same time" do
    @b1.lock do
      expect { @b2.lock.unlock }.to_not raise_exception
      @b1.should be_locked
    end
  end

  it "works if you call Lock1.lock and Lock2.lock with the same owner"

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

  it "can detect broken or expired locks" do
    no_owner = nil
    past     = 1
    present  = 2
    future   = 3

    @a.is_deleteable?( no_owner, nil,    present ).should be_false # no lock => not expired

    @a.is_deleteable?( no_owner, future, present ).should be_true  # broken => expired
    @a.is_deleteable?( no_owner, past,   present ).should be_true  # broken => expired
    @a.is_deleteable?( @a_owner, nil,    present ).should be_true  # broken => expired

    @a.is_deleteable?( @a_owner, future, present ).should be_false # current; not expired

    @a.is_deleteable?( @a_owner, past,   present ).should be_true  # expired

    # We leave [ present, present ] to be unspecified.
  end

end
