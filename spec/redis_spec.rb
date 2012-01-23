require "helper"

# These are here to be sure Redis works the way we expect.

describe Redis, redis: true do

  it "can do a multi setnx" do
    redis.mapped_msetnx "one" => "uno", "two" => "dos"
    redis.get("one").should eq("uno")
    redis.get("two").should eq("dos")
  end

  it "can delete multiple items" do
    redis.set "one", "uno"
    redis.set "two", "dos"
    x = redis.multi do |mredis|
      mredis.del "one"
      mredis.del "two"
    end
    x.should eq( [1,1] )
    redis.get("one").should be_nil
    redis.get("two").should be_nil
  end

  it "can detect multi success" do
    redis.set "one", "uno"
    with_watch( redis, "one" ) do
      x = redis.multi do |mredis|
        mredis.del "one"
      end
      x.should eq([1])
    end
  end

  it "can detect multi failures" do
    redis.set "one", "uno"
    with_watch( redis,  "one" ) do
      x = redis.multi do |mredis|
        mredis.del "one"
        redis2.set "one", "ichi"
      end
      x.should be_nil
    end
  end

end
