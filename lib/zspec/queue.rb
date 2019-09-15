module ZSpec
  class Queue
    def initialize(options = {})
      @sink                 = options[:sink]
      @timeout              = options[:timeout].to_i
      @shutdown             = options[:shutdown].to_i
      @retries              = options[:retries].to_i
      @counter_name         = options[:queue_name] + ":count"
      @pending_queue_name   = options[:queue_name] + ":pending"
      @process_queue_name   = options[:queue_name] + ":processing"
      @done_queue_name      = options[:queue_name] + ":done"
      @workers_queue_name   = options[:queue_name] + ":workers"
      @metadata_hash_name   = options[:queue_name] + ":metadata"
      @runtime_hash_name    = "runtimes"
    end

    def cleanup
      @sink.del(@counter_name)
      @sink.del(@pending_queue_name)
      @sink.del(@process_queue_name)
      @sink.del(@done_queue_name)
      @sink.del(@workers_queue_name)
      @sink.del(@metadata_hash_name)
    end

    def enqueue(message)
      @sink.lpush(@pending_queue_name, message)
      @sink.incr(@counter_name)
    end

    def proccess_pending(timeout = 0)
      while proccessing? do
        break if is_shutdown?(worker_name)
        register_worker(worker_name)

        message = @sink.brpoplpush(@pending_queue_name, @process_queue_name, timeout)
        next if message.nil? || message.empty?

        @sink.hset(@metadata_hash_name, timeout_key(message), @sink.time)

        yield(message)
      end

      clear_worker(worker_name)
    end

    def proccess_done(timeout = 0)
      while proccessing? do
        expire_proccessing
        expire_workers
        shutdown_excess_workers

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
        if is_expired?(message, @timeout)
          @sink.lrem(@process_queue_name, message)
          @sink.lpush(@pending_queue_name, message)
          @sink.hdel(@metadata_hash_name, timeout_key(message))
        end
      end
    end

    def expire_workers
      @sink.lrange(@workers_queue_name, 0, -1).each do |key|
        clear_worker(key) if is_expired?(key, @shutdown)
      end
    end

    def shutdown_excess_workers
      jobs = @sink.get(@counter_name).to_i
      worker_count = @sink.llen(@workers_queue_name)

      if worker_count > jobs
        puts "jobs #{jobs}\nworkers #{worker_count}\nshutting down #{worker_count - jobs} workers"
        @sink.lrange(@workers_queue_name, 0, worker_count - jobs - 1).each do |key|
          @sink.hset(@metadata_hash_name, status_key(key), "shutdown")
        end
      end
    end

    def worker_name
      ENV['WORKER_NAME']
    end

    def is_shutdown?(key)
      @sink.hget(@metadata_hash_name, status_key(key)) == "shutdown"
    end

    def clear_worker(key)
      @sink.lrem(@workers_queue_name, key)
      @sink.hdel(@metadata_hash_name, status_key(key))
      @sink.hdel(@metadata_hash_name, timeout_key(key))
    end

    def register_worker(key)
      @sink.lpush(@workers_queue_name, key)
      @sink.hset(@metadata_hash_name, status_key(key), "running")
      @sink.hset(@metadata_hash_name, timeout_key(key), @sink.time)
    end

    def is_expired?(key, timeout)
      time = @sink.hget(@metadata_hash_name, timeout_key(key)).to_i
      (@sink.time - time) > timeout
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

    def status_key(message)
      "#{message}:status"
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
