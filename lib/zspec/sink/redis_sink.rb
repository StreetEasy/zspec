module ZSpec
  module Sink
    class RedisSink
      def initialize(redis:)
        @redis = redis
      end

      def time
        @redis.time.first
      end

      def expire(key, seconds)
        @redis.expire(key, seconds)
      end

      def lpush(key, value)
        @redis.lpush(key, value)
      end

      def lrem(key, value)
        @redis.lrem(key, 0, value)
      end

      def lrange(key, start, stop)
        @redis.lrange(key, start, stop)
      end

      def rpush(key, value)
        @redis.rpush(key, value)
      end

      def brpop(key, timeout = 0)
        _list, message = @redis.brpop(key, timeout: timeout)
        message
      end

      def brpoplpush(source, destination, timeout = 0)
        @redis.brpoplpush(source, destination, timeout: timeout)
      end

      def hget(key, field)
        @redis.hget(key, field)
      end

      def hgetall(key)
        @redis.hgetall(key)
      end

      def hset(key, field, value)
        @redis.hset(key, field, value)
      end

      def hdel(key, field)
        @redis.hdel(key, field)
      end

      def hincrby(key, field, value)
        @redis.hincrby(key, field, value)
      end

      def incr(key)
        @redis.incr(key)
      end

      def decr(key)
        @redis.decr(key)
      end

      def get(key)
        @redis.get(key)
      end

      def set(key, value)
        @redis.set(key, value)
      end
    end
  end
end
