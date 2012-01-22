require "helper"

describe Redis::Lock, redis: true do

  it "can acquire and release a lock"
  it "can acquire and release a lock" do
    redis.lock("test") { true }
    expect { redis.lock("test") { true } }.to_not raise_exception
    expect { redis.lock("test") { true } }.to_not raise_exception
  end

end
