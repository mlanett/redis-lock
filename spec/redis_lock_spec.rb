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
      expect(hers).to be_locked
    end
    expect(hers).to_not be_locked
  end

  context "when using blocks" do

    it 'returns the return value of the block' do
      expect( hers.lock { 1 } ).to eql(1)
    end

    it "passes the lock into a supplied block" do
      hers.lock do |lock|
        expect(lock).to be_an_instance_of(Redis::Lock)
      end
    end

    it "passes the lock into a supplied lambda" do
      action = ->(lock) do
        expect(lock).to be_an_instance_of(Redis::Lock)
      end
      hers.lock( &action )
    end

  end

  it "can prevent other use of a lock" do
    hers.lock do
      expect { his.lock; his.unlock }.to raise_exception
    end
    expect { his.lock; his.unlock }.to_not raise_exception
  end

  it "can lock two different items at the same time" do
    his.lock do
      expect { his_other.lock; his_other.unlock }.to_not raise_exception
      expect(his).to be_locked
    end
  end

  it "does not support nesting" do
    hers.lock do
      expect { her_same.lock }.to raise_exception
    end
  end

  it "can acquire a lock" do
    expect(hers.do_lock).to be_truthy
  end

  it "can release a lock" do
    hers.lock; hers.release_lock
  end

  it "can use a timeout" do
    expect( hers.with_timeout(1) { true } ).to be_truthy
    expect( hers.with_timeout(1) { false } ).to be_falsy
    # a few attempts are OK
    results = [ false, false, true ]
    expect( hers.with_timeout(1) { results.shift }).to be_truthy
    # this is too many attemps
    results = [ false, false, false, false, false, false, false, false, false, false, true ]
    expect( hers.with_timeout(1) { results.shift } ).to be_falsy
  end

  it "does not take too long to time out" do
    start = Time.now.to_f
    hers.with_timeout(1) { false }
    time = Time.now.to_f - start
    expect(time).to be_within(0.2).of(1)
  end

  it "can time out an expired lock" do
    hers.life = 0.01
    hers.lock
    # don't unlock it, let hers time out
    expect { his.lock(10); his.unlock }.to_not raise_exception
  end

  it "can extend the life of a lock" do
    hers.life = 0.01
    hers.lock
    hers.extend_life(100)
    expect { his.lock; his.unlock }.to raise_exception
    hers.unlock
  end

  example "How to get a lock using the helper." do
    redis.lock "mykey", life: 10, acquire: 1 do |lock|
      lock.extend_life 10
    end
  end

end
