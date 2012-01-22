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

end
