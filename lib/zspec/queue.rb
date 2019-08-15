module ZSpec
  class Queue
    def initialize(options = {})
      @sink               = options[:sink]
      @timeout            = options[:timeout].to_i
      @retries            = options[:retries].to_i
      @counter_name       = options[:queue_name] + ":count"
      @pending_queue_name = options[:queue_name] + ":pending"
      @process_queue_name = options[:queue_name] + ":processing"
      @done_queue_name    = options[:queue_name] + ":done"
      @metadata_hash_name = options[:queue_name] + ":metadata"
      @runtime_hash_name  = "runtimes"
    end

    def cleanup
      @sink.del(@counter_name)
      @sink.del(@pending_queue_name)
      @sink.del(@process_queue_name)
      @sink.del(@done_queue_name)
      @sink.del(@metadata_hash_name)
    end

    def enqueue(message)
      @sink.lpush(@pending_queue_name, message)
      @sink.incr(@counter_name)
    end

    def proccess_pending(timeout = 0)
      while proccessing? do
        message = @sink.brpoplpush(@pending_queue_name, @process_queue_name, timeout)
        next if message.nil? || message.empty?

        @sink.hset(@metadata_hash_name, timeout_key(message), @sink.time)

        yield(message)
      end
    end

    def proccess_done(timeout = 0)
      while proccessing? do
        expire_proccessing

        _list, message = @sink.brpop(@done_queue_name, timeout)
        next if message.nil? || message.empty?

        next if @sink.hget(@metadata_hash_name, dedupe_key(message))

        results = @sink.hget(@metadata_hash_name, results_key(message))
        next if results.nil? || results.empty?

        yield(results)

        @sink.hset(@metadata_hash_name, dedupe_key(message), true)
        @sink.decr(@counter_name)
      end
    end

    def resolve(failed, message, runtime, results)
      if failed && (count = retry_count(message)) && (count < @retries)
        retry_message(message, count)
      else
        resolve_message(message, runtime, results)
      end
    end

    private

    def expire_proccessing
      @sink.lrange(@process_queue_name, 0, -1).each do |message|
        if is_expired?(message)
          @sink.lrem(@process_queue_name, message)
          @sink.lpush(@pending_queue_name, message)
          @sink.hdel(@metadata_hash_name, timeout_key(message))
        end
      end
    end

    def is_expired?(message)
      proccess_time = @sink.hget(@metadata_hash_name, timeout_key(message)).to_i
      (@sink.time - proccess_time) > @timeout
    end

    def retry_message(message, count)
      @sink.hdel(@metadata_hash_name, timeout_key(message))
      @sink.hset(@metadata_hash_name, retry_key(message), count+1)
    end

    def resolve_message(message, runtime, results)
      @sink.hset(@runtime_hash_name, message, runtime)
      @sink.hset(@metadata_hash_name, results_key(message), results)
      @sink.lrem(@process_queue_name, message)
      @sink.lpush(@done_queue_name, message)
    end

    def retry_count(message)
      @sink.hget(@metadata_hash_name, retry_key(message)).to_i
    end

    def proccessing?
      @sink.get(@counter_name).to_i > 0
    end

    def timeout_key(message)
      "#{message}:timeout"
    end

    def results_key(message)
      "#{message}:results"
    end

    def retry_key(message)
      "#{message}:retries"
    end

    def dedupe_key(message)
      "#{message}:dedupe"
    end
  end
end
