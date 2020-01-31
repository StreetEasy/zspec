require "zspec/util"

module ZSpec
  class Queue
    attr_reader :counter_name, :pending_queue_name, :processing_queue_name,
      :done_queue_name, :metadata_hash_name, :workers_ready_key_name

    include ZSpec::Util

    def initialize(sink:, build_prefix:, retries:, timeout:)
      @sink                   = sink
      @retries                = retries.to_i
      @timeout                = timeout.to_i
      @counter_name           = build_prefix + ":count"
      @pending_queue_name     = build_prefix + ":pending"
      @processing_queue_name  = build_prefix + ":processing"
      @done_queue_name        = build_prefix + ":done"
      @metadata_hash_name     = build_prefix + ":metadata"
      @workers_ready_key_name = build_prefix + ":ready"
    end

    def cleanup(expire_seconds = EXPIRE_SECONDS)
      @sink.expire(@counter_name, expire_seconds)
      @sink.expire(@pending_queue_name, expire_seconds)
      @sink.expire(@processing_queue_name, expire_seconds)
      @sink.expire(@done_queue_name, expire_seconds)
      @sink.expire(@metadata_hash_name, expire_seconds)
      @sink.expire(@workers_ready_key_name, expire_seconds)
    end

    def enqueue(messages)
      messages.each do |message|
        @sink.lpush(@pending_queue_name, message)
        @sink.incr(@counter_name)
      end
      @sink.set(@workers_ready_key_name, true)
    end

    def done_queue
      Enumerator.new do |yielder|
        until workers_ready? && complete?
          expire_processing

          _list, message = @sink.brpop(@done_queue_name, timeout: 1)
          if message.nil?
            yielder << [nil, nil]
            next
          end

          if @sink.hget(@metadata_hash_name, dedupe_key(message))
            yielder << [nil, nil]
            next
          end

          results = @sink.hget(@metadata_hash_name, results_key(message))
          if results.nil?
            yielder << [nil, nil]
            next
          end

          stdout = @sink.hget(@metadata_hash_name, stdout_key(message))

          @sink.hset(@metadata_hash_name, dedupe_key(message), true)
          @sink.decr(@counter_name)

          yielder << [results, stdout]
        end
      end
    end

    def pending_queue
      Enumerator.new do |yielder|
        until workers_ready? && complete?
          puts 'from pending_queue', @pending_queue_name, @processing_queue_name
          message = @sink.brpoplpush(@pending_queue_name, @processing_queue_name, timeout: 1)
          if message.nil?
            puts 'no pending messages'
            yielder << nil
            next
          end
          @sink.hset(@metadata_hash_name, timeout_key(message), @sink.time.first)
          yielder << message
        end
      end
    end

    def resolve(failed, message, results, stdout)
      if failed && (count = retry_count(message)) && (count < @retries)
        retry_message(message, count)
      else
        resolve_message(message, results, stdout)
      end
    end

    private

    def expire_processing
      processing.each do |message|
        next unless expired?(message)

        @sink.lrem(@processing_queue_name, 0, message)
        @sink.rpush(@pending_queue_name, message)
        @sink.hdel(@metadata_hash_name, timeout_key(message))
      end
    end

    def workers_ready?
      @sink.get(@workers_ready_key_name)
    end

    def processing
      @sink.lrange(@processing_queue_name, 0, -1)
    end

    def complete?
      @sink.get(@counter_name).to_i == 0
    end

    def retry_count(message)
      @sink.hget(@metadata_hash_name, retry_key(message)).to_i
    end

    def expired?(message)
      proccess_time = @sink.hget(@metadata_hash_name, timeout_key(message)).to_i
      (@sink.time.first - proccess_time) > @timeout
    end

    def resolve_message(message, results, stdout)
      @sink.hset(@metadata_hash_name, stdout_key(message), stdout)
      @sink.hset(@metadata_hash_name, results_key(message), results)
      @sink.lrem(@processing_queue_name, 0, message)
      @sink.lpush(@done_queue_name, message)
    end

    def retry_message(message, count)
      @sink.hdel(@metadata_hash_name, timeout_key(message))
      @sink.hset(@metadata_hash_name, retry_key(message), count + 1)
    end
  end
end
