require "spec_helper"

describe ZSpec::Sink::MemorySink do
  before :each do
    @key1 = "key1"
    @key2 = "key2"
    @key3 = "key3"
    @val1 = "val1"
    @val2 = "val2"
    @val3 = "val3"
  end

  describe "#rpush" do
    it "adds item to the end of the queue" do
      @sink.rpush(@key1, @val1)
      @sink.rpush(@key1, @val2)
      expect(@state).to include(@key1 => [@val1, @val2])
    end
  end

  describe "#rpop" do
    it "removes item from the end of the queue" do
      @sink.rpush(@key1, @val1)
      expect(@sink.rpop(@key1)).to eq(@val1)
      expect(@state).to include(@key1 => [])
    end
  end

  describe "#lpush" do
    it "adds item to the begining of the queue" do
      @sink.lpush(@key1, @val1)
      @sink.lpush(@key1, @val2)
      expect(@state).to include(@key1 => [@val2, @val1])
    end
  end

  describe "#lrem" do
    it "removes item from the begining of the queue" do
      @sink.lpush(@key1, @val1)
      @sink.lrem(@key1, 0, @val1)
      expect(@state).to include(@key1 => [])
    end
  end

  describe "#lrange" do
    it "returns a slice of the queue" do
      @sink.rpush(@key1, @val1)
      @sink.rpush(@key1, @val2)
      @sink.rpush(@key1, @val3)
      expect(@sink.lrange(@key1, 0, -1)).to eq([@val1, @val2, @val3])
      expect(@sink.lrange(@key1, 0, 2)).to eq([@val1, @val2, @val3])
      expect(@sink.lrange(@key1, 0, 1)).to eq([@val1, @val2])
    end
  end

  describe "#brpoplpush" do
    it "pops from queue 1, and pushes to begining of queue 2" do
      @sink.lpush(@key1, @val1)
      @sink.brpoplpush(@key1, @key2)
      expect(@state).to include(@key1 => [])
      expect(@state).to include(@key2 => [@val1])
    end

    it "returns the pop'd message" do
      @sink.lpush(@key1, @val1)
      expect(@sink.brpoplpush(@key1, @key2)).to eq(@val1)
    end
  end

  describe "#incr" do
    it "increments the counter" do
      @sink.incr(@key1)
      @sink.incr(@key1)
      expect(@state).to include(@key1 => 2)
    end
  end

  describe "#decr" do
    it "decrements the counter" do
      @sink.decr(@key1)
      @sink.decr(@key1)
      expect(@state).to include(@key1 => -2)
    end
  end

  describe "#get" do
    it "gets a value" do
      @sink.incr(@key1)
      expect(@sink.get(@key1)).to eq(1)
    end
  end

  describe "#set" do
    it "sets a value" do
      @sink.set(@key1, 2)
      expect(@sink.get(@key1)).to eq(2)
    end
  end

  describe "#expire" do
    it "adds an expiration to the queue" do
      @sink.expire(@key1, 10)
      expect(@expirations).to include(@key1 => 10)
    end
  end

  describe "#hset" do
    it "sets a hash value" do
      @sink.hset(@key1, @key2, @val1)
      expect(@state).to include(@key1 => { @key2 => @val1 })
    end
  end

  describe "#hget" do
    it "gets a hash value" do
      @sink.hset(@key1, @key2, @val1)
      expect(@sink.hget(@key1, @key2)).to eq(@val1)
    end
  end

  describe "#hgetall" do
    it "gets a full hash" do
      @sink.hset(@key1, @key2, @val1)
      expect(@sink.hgetall(@key1)).to eq(@key2 => @val1)
    end
  end

  describe "#hdel" do
    it "deletes a hash value" do
      @sink.hset(@key1, @key2, @val1)
      @sink.hdel(@key1, @key2)
      expect(@sink.hget(@key1, @key2)).to eq(nil)
    end
  end
end
