require "helper"

describe Redis::Lock, redis: true do

  let(:non) { nil }
  let(:her) { "Alice" }
  let(:him) { "Bob" }
  let(:hers)       { Redis::Lock.new( redis, "alpha", owner: her ) }
  let(:her_same)   { Redis::Lock.new( redis, "alpha", owner: her ) }
  let(:his)        { Redis::Lock.new( redis, "alpha", owner: him ) }
  let(:his_other)  { Redis::Lock.new( redis, "beta",  owner: him ) }
  let(:past   ) { 1 }
  let(:present) { 2 }
  let(:future ) { 3 }

  it "can acquire and release a lock" do
    hers.lock do
      hers.should be_locked
    end
    hers.should_not be_locked
  end

  it "can prevent other use of a lock" do
    hers.lock do
      expect { his.lock.unlock }.to raise_exception
    end
    expect { his.lock.unlock }.to_not raise_exception
  end

  it "can lock two different items at the same time" do
    his.lock do
      expect { his_other.lock.unlock }.to_not raise_exception
      his.should be_locked
    end
  end

  it "does not support nesting" do
    hers.lock do
      expect { her_same.lock }.to raise_exception
    end
  end

  it "can acquire a lock" do
    hers.do_lock.should be_true
  end

  it "can release a lock" do
    hers.lock.release_lock
  end

  it "can use a timeout" do
    hers.with_timeout(1) { true }.should be_true
    hers.with_timeout(1) { false }.should be_false
    # a few attempts are OK
    results = [ false, false, true ]
    hers.with_timeout(1) { results.shift }.should be_true
    # this is too many attemps
    results = [ false, false, false, false, false, true ]
    hers.with_timeout(1) { results.shift }.should be_false
  end

  it "does not take too long to time out" do
    start = Time.now.to_f
    hers.with_timeout(1) { false }
    time = Time.now.to_f - start
    time.should be_within(0.2).of(1.0)
  end

  it "can time out an expired lock" do
    hers.life = 1
    hers.lock
    # don't unlock it, let hers time out
    expect { his.lock(2).unlock }.to_not raise_exception
  end

  it "can determine if it is locked" do
    hers.is_locked?( non, nil,    present ).should be_false
    hers.is_locked?( non, future, present ).should be_false
    hers.is_locked?( non, past,   present ).should be_false
    hers.is_locked?( her, nil,    present ).should be_false
    hers.is_locked?( her, future, present ).should be_true  # the only valid case
    hers.is_locked?( her, past,   present ).should be_false
    hers.is_locked?( him, nil,    present ).should be_false
    hers.is_locked?( him, future, present ).should be_false
    hers.is_locked?( him, past,   present ).should be_false
    # We leave [ present, present ] to be unspecified.
  end

  it "can detect broken or expired locks" do
    hers.is_deleteable?( non, nil,    present ).should be_false # no lock => not expired

    hers.is_deleteable?( non, future, present ).should be_true  # broken => expired
    hers.is_deleteable?( non, past,   present ).should be_true  # broken => expired
    hers.is_deleteable?( her, nil,    present ).should be_true  # broken => expired

    hers.is_deleteable?( her, future, present ).should be_false # current; not expired

    hers.is_deleteable?( her, past,   present ).should be_true  # expired

    # We leave [ present, present ] to be unspecified.
  end

end
