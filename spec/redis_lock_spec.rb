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


  it "can use a timeout" do
    @it.with_timeout(1) { true }.should be_true
    @it.with_timeout(1) { false }.should be_false
    results = [ false, false, true ]
    @it.with_timeout(1) { results.shift }.should be_true
  end

  it "can use msetnx" do
    redis.msetnx "one", "uno", "two", "dos"
    redis.get("one").should eq("uno")
    redis.get("two").should eq("dos")
  end

  it "can acquire a lock" do
    a = Redis::Lock.new( redis, "test" )
    a.successfully_locked_key?.should be_true
  end

end