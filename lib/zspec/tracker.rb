module ZSpec
  class Tracker
    attr_reader :runtimes_hash_name, :alltime_failures_hash_name, :current_failures_hash_name, :threshold

    def initialize(build_prefix:, sink:, threshold:)
      @sink                       = sink
      @threshold                  = threshold
      @runtimes_hash_name         = "runtimes"
      @alltime_failures_hash_name = "failures"
      @current_failures_hash_name = build_prefix + ":failures"
    end

    def track_runtime(message, runtime)
      @sink.hset(@runtimes_hash_name, message, runtime)
    end

    def track_failures(failures)
      failures.map { |h| h[:id] }.each do |message|
        save_failure(@alltime_failures_hash_name, message, update_failure(@alltime_failures_hash_name, message))
        save_failure(@current_failures_hash_name, message, update_failure(@current_failures_hash_name, message))
      end
    end

    def all_runtimes
      @sink.hgetall(@runtimes_hash_name)
    end

    def alltime_failures
      @sink.hgetall(@alltime_failures_hash_name)
        .map(&method(:parse_failure))
        .select(&method(:filter_by_threshold))
        .sort_by(&method(:failure_count))
        .reverse
    end

    def current_failures
      @sink.hgetall(@current_failures_hash_name)
        .map(&method(:parse_failure))
        .sort_by(&method(:failure_count))
        .reverse
    end

    def cleanup(expire_seconds = 1800)
      @sink.expire(@current_failures_hash_name, expire_seconds)
    end

    private

    def parse_failure(_message, failure)
      JSON.parse(failure)
    end

    def update_failure(hash, message)
      failure = JSON.parse(@sink.hget(hash, message) || "{\"count\":0}")
      failure.merge("message" => message, "last_failure" => @sink.time, "count" => failure["count"].to_i + 1)
    end

    def save_failure(hash, message, failure)
      @sink.hset(hash, message, failure.to_json)
    end

    def filter_by_threshold(failure)
      (@sink.time - failure["last_failure"].to_i) < @threshold
    end

    def failure_count(failure)
      failure["count"].to_i
    end
  end
end
