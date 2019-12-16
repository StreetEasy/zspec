module ZSpec
  module Sink
    class MemorySink
      def initialize(state:, expirations:)
        @state       = state
        @expirations = expirations
      end

      def time
        @state[:time]
      end

      def expire(key, seconds)
        @expirations[key] = seconds
      end

      def lpush(key, value)
        (@state[key] ||= []).unshift(value)
      end

      def lrem(key, value)
        (@state[key] ||= []).delete(value)
      end

      def lrange(key, start, stop)
        (@state[key] ||= [])[start..stop]
      end

      def rpush(key, value)
        (@state[key] ||= []).push(value)
      end

      def rpop(key)
        (@state[key] ||= []).pop
      end

      def brpop(key, _timeout = 0)
        rpop(key)
      end

      def brpoplpush(source, destination, _timeout = 0)
        message = rpop(source)
        lpush(destination, message)
        message
      end

      def hget(key, field)
        (@state[key] ||= {})[field]
      end

      def hgetall(key)
        @state[key] ||= {}
      end

      def hset(key, field, value)
        (@state[key] ||= {})[field] = value
      end

      def hdel(key, field)
        (@state[key] ||= {}).delete(field)
      end

      def hincrby(key, field, value)
        (@state[key] ||= {})[field] = (hget(key, field) || 0) + 1
      end

      def incr(key)
        @state[key] ||= 0
        @state[key] += 1
      end

      def decr(key)
        @state[key] ||= 0
        @state[key] -= 1
      end

      def set(key, value)
        @state[key] = value
      end

      def get(key)
        @state[key]
      end
    end
  end
end
