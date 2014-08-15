require "helper"

# These are here to be sure Redis works the way we expect.

describe Redis, redis: true do

  it "can do a multi setnx" do
    redis.mapped_msetnx "one" => "uno", "two" => "dos"
    expect(redis.get("one")).to eq("uno")
    expect(redis.get("two")).to eq("dos")
  end

  it "can delete multiple items" do
    redis.set "one", "uno"
    redis.set "two", "dos"
    x = redis.multi do |multi|
      multi.del "one"
      multi.del "two"
    end
    expect(x).to eq( [1,1] )
    expect(redis.get("one")).to be_nil
    expect(redis.get("two")).to be_nil
  end

  it "can detect multi success" do
    redis.set "one", "uno"
    with_watch( redis, "one" ) do
      x = redis.multi do |multi|
        multi.del "one"
      end
      expect(x).to eq([1])
    end
  end

  it "can detect multi failures" do
    redis.set "one", "uno"
    with_watch( redis,  "one" ) do
      x = redis.multi do |multi|
        multi.del "one"
        other.set "one", "ichi"
      end
      expect(x).to be_nil
    end
  end

end
