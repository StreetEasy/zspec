module ZSpec
  class Tracker
    attr_reader :runtimes_hash_name, :alltime_failures_hash_name, :current_failures_hash_name, :threshold

    def initialize(build_prefix:, sink:, threshold:, hostname:)
      @sink                       = sink
      @threshold                  = threshold
      @hostname                   = hostname
      @runtimes_hash_name         = "runtimes:v1"
      @alltime_failures_hash_name = "failures:v1"
      @current_failures_hash_name = build_prefix + ":failures"
      @sequence_hash_name         = build_prefix + ":sequence"
    end

    def track_sequence(message)
      puts "tracking sequence #{message}" 
      sequence = (@sink.hget(@sequence_hash_name, @hostname) || "").split(",")
      puts "sequence is #{sequence}"
      sequence << message
      puts "sequence with message is #{sequence}"
      @sink.hset(@sequence_hash_name, @hostname, sequence.join(","))
      puts "sequence set"
    end

    def track_runtime(message, runtime)
      @sink.hset(@runtimes_hash_name, message, runtime)
    end

    def track_failures(failures)
      failures.map { |h| h[:id] }.each do |message|
        @sink.hincrby(@alltime_failures_hash_name, count_key(message), 1)
        @sink.hset(@alltime_failures_hash_name, time_key(message), @sink.time.first)

        @sink.hincrby(@current_failures_hash_name, count_key(message), 1)
        @sink.hset(@current_failures_hash_name, time_key(message), @sink.time.first)
        @sink.hset(@current_failures_hash_name, sequence_key(message), sequence)
      end
    end

    def all_runtimes
      @sink.hgetall(@runtimes_hash_name)
    end

    def alltime_failures
      parse_failures(
        @sink.hgetall(@alltime_failures_hash_name)
      )
      .select(&method(:filter_by_threshold))
      .sort_by(&method(:failure_count))
      .reverse
    end

    def current_failures
      parse_failures(
        @sink.hgetall(@current_failures_hash_name)
      )
      .sort_by(&method(:failure_count))
      .reverse
    end

    def cleanup(expire_seconds = EXPIRE_SECONDS)
      @sink.expire(@current_failures_hash_name, expire_seconds)
      @sink.expire(@sequence_hash_name, expire_seconds)
    end

    def time_key(message)
      "#{message}:time"
    end

    def count_key(message)
      "#{message}:count"
    end

    def sequence_key(message)
      "#{message}:sequence"
    end

    private

    def sequence
      @sink.hget(@sequence_hash_name, @hostname) || ""
    end

    def parse_failures(failures)
      memo = {}
      failures.each do |key, value|
        message = key.gsub(/\:time|\:count|\:sequence/, '')
        memo[message] ||= {}
        memo[message]["message"] = message
        memo[message]["count"] = value.to_i if key.end_with?(":count")
        memo[message]["last_failure"] = value.to_i if key.end_with?(":time")
        memo[message]["sequence"] = value.split(",") if key.end_with?(":sequence")
      end
      memo.values
    end

    def filter_by_threshold(failure)
      (@sink.time.first - failure["last_failure"].to_i) < @threshold
    end

    def failure_count(failure)
      failure["count"].to_i
    end
  end
end
