module ZSpec
  class Tracker
    attr_reader :runtimes_hash_name, :failures_hash_name
    def initialize(sink:, threshold:)
      @sink               = sink
      @threshold          = threshold
      @runtimes_hash_name = "runtimes"
      @failures_hash_name = "failures"
    end

    def track_runtime(message, runtime)
      @sink.hset(@runtimes_hash_name, message, runtime)
    end

    def all_runtimes
      @sink.hgetall(@runtimes_hash_name)
    end

    def track_failures(failures)
      failures.map { |h| h[:id] }.each do |message|
        save_failure(message, update_failure(message))
      end
    end

    def recent_failures
      failures
        .map(&method(:parse_failure))
        .select(&method(:filter_by_threshold))
        .sort_by(&method(:failure_count))
        .reverse
    end

    private

    def parse_failure(_message, failure)
      JSON.parse(failure)
    end

    def update_failure(message)
      failure = JSON.parse(@sink.hget(@failures_hash_name, message) || "{\"count\":0}")
      failure.merge("message" => message, "last_failure" => @sink.time, "count" => failure["count"].to_i + 1)
    end

    def save_failure(message, failure)
      @sink.hset(@failures_hash_name, message, failure.to_json)
    end

    def failures
      @sink.hgetall(@failures_hash_name)
    end

    def filter_by_threshold(failure)
      (@sink.time - failure["last_failure"].to_i) < @threshold
    end

    def failure_count(failure)
      failure["count"].to_i
    end
  end
end
