module ZSpec
  module Sink
    class MemorySink
      def initialize
        @queues = {}
      end

      def get(queue_name)
        @queues[queue_name]
      end

      def set(queue_name, value)
        @queues[queue_name] = value
      end

      def incr(queue_name, value)
        @queues[queue_name] = (@queues[queue_name] ||= 0)+1
      end

      def decr(queue_name, value)
        @queues[queue_name] = (@queues[queue_name] ||= 0)-1
      end

      def pop(queue_name)
        get_queue(queue_name).pop
      end

      def push(queue_name, message)
        get_queue(queue_name).push(message)
      end

      def length(queue_name)
        get_queue(queue_name).length
      end

      def delete(queue_name, message)
        get_queue(queue_name).delete(message)
      end

      def clear(queue_name)
        @queues.delete(queue_name)
      end

      private

      def get_queue(name)
        @queues[name] ||= []
      end
    end
  end
end
