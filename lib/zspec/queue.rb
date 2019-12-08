require "pry"

module ZSpec
  class Queue
    attr_reader :counter_name, :pending_queue_name, :process_queue_name,
      :done_queue_name, :metadata_hash_name, :workers_ready
    def initialize(sink:, queue_name:, retries:, timeout:)
      @sink               = sink
      @retries            = retries.to_i
      @timeout            = timeout.to_i
      @counter_name       = queue_name + ":count"
      @pending_queue_name = queue_name + ":pending"
      @process_queue_name = queue_name + ":processing"
      @done_queue_name    = queue_name + ":done"
      @metadata_hash_name = queue_name + ":metadata"
      @workers_ready      = queue_name + ":ready"
    end

    def cleanup
      @sink.expire(@counter_name, 1800)
      @sink.expire(@pending_queue_name, 1800)
      @sink.expire(@process_queue_name, 1800)
      @sink.expire(@done_queue_name, 1800)
      @sink.expire(@metadata_hash_name, 1800)
      @sink.expire(@workers_ready, 1800)
    end

    def enqueue(messages)
      messages.each do |message|
        @sink.lpush(@pending_queue_name, message)
        @sink.incr(@counter_name)
      end
      @sink.set(@workers_ready, true)
    end

    def proccess_done(timeout = 0, &block)
      return unless block_given?

      next_done(timeout, &block) while processing?
    end

    def proccess_pending(timeout = 0, &block)
      return unless block_given?

      sleep 1 until workers_ready?

      next_pending(timeout, &block) while processing?
    end

    def next_done(timeout = 0)
      expire_processing

      message = @sink.brpop(@done_queue_name, timeout)
      return if message.nil? || message.empty?

      return if @sink.hget(@metadata_hash_name, dedupe_key(message))

      results = @sink.hget(@metadata_hash_name, results_key(message))
      return if results.nil? || results.empty?

      stdout = @sink.hget(@metadata_hash_name, stdout_key(message))

      yield(results, stdout) if block_given?

      @sink.hset(@metadata_hash_name, dedupe_key(message), true)
      @sink.decr(@counter_name)
    end

    def next_pending(timeout = 0)
      message = @sink.brpoplpush(@pending_queue_name, @process_queue_name, timeout)
      return if message.nil? || message.empty?

      @sink.hset(@metadata_hash_name, timeout_key(message), @sink.time)
      yield(message) if block_given?
    end

    def resolve(failed, message, results, stdout)
      if failed && (count = retry_count(message)) && (count < @retries)
        retry_message(message, count)
      else
        resolve_message(message, results, stdout)
      end
    end

    def expire_processing
      processing.each do |message|
        next unless expired?(message)

        @sink.lrem(@process_queue_name, message)
        @sink.rpush(@pending_queue_name, message)
        @sink.hdel(@metadata_hash_name, timeout_key(message))
      end
    end

    def workers_ready?
      @sink.get(@workers_ready)
    end

    def processing
      @sink.lrange(@process_queue_name, 0, -1)
    end

    def processing?
      @sink.get(@counter_name).to_i > 0
    end

    def retry_count(message)
      @sink.hget(@metadata_hash_name, retry_key(message)).to_i
    end

    def expired?(message)
      proccess_time = @sink.hget(@metadata_hash_name, timeout_key(message)).to_i
      (@sink.time - proccess_time) > @timeout
    end

    def resolve_message(message, results, stdout)
      @sink.hset(@metadata_hash_name, stdout_key(message), stdout)
      @sink.hset(@metadata_hash_name, results_key(message), results)
      @sink.lrem(@process_queue_name, message)
      @sink.lpush(@done_queue_name, message)
    end

    def retry_message(message, count)
      @sink.hdel(@metadata_hash_name, timeout_key(message))
      @sink.hset(@metadata_hash_name, retry_key(message), count + 1)
    end

    def timeout_key(message)
      "#{message}:timeout"
    end

    def stdout_key(message)
      "#{message}:stdout"
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
