module ZSpec
  module Sink
    class RedisSink
      def initialize(options = {})
        @redis = options[:redis]
      end

      def get(queue_name)
        @redis.get queue_name
      end

      def set(queue_name, value)
        @redis.set(queue_name, value)
      end

      def incr(queue_name)
        @redis.incr queue_name
      end

      def decr(queue_name)
        @redis.decr queue_name
      end

      def pop(queue_name)
        @redis.lpop queue_name
      end

      def push(queue_name, message)
        @redis.rpush(queue_name, message)
      end

      def length(queue_name)
        @redis.llen queue_name
      end

      def delete(queue_name, message)
        @redis.lrem(queue_name, 0, message)
      end

      def clear(queue_name)
        @redis.del queue_name
      end
    end
  end
end
