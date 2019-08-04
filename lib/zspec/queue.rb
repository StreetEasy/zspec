module ZSpec
  class Queue
    def initialize(options = {})
      @sink = options[:sink]
      @queue_name = options[:queue_name]
      @process_queue_name = options[:process_queue_name] || options[:queue_name] + ".process"
      @last_message = nil
    end

    def clear
      @sink.clear @queue_name
      @sink.clear @process_queue_name
    end

    def pop
      @last_message = @sink.pop @queue_name
      @sink.push(@process_queue_name, @last_message) unless @last_message.nil?
      @last_message
    end

    def push(message)
      @sink.push(@queue_name, message)
    end

    def length
      @sink.length @queue_name
    end

    def empty?
      length <= 0
    end

    def commit
      @sink.delete(@process_queue_name, @last_message)
    end

    def refill
      while (message = @sink.pop(@process_queue_name))
        @sink.push(@queue_name, message) unless message.nil?
      end
    end

    alias size  length
    alias dec   pop
    alias shift pop
    alias enc   push
    alias <<    push
  end
end
