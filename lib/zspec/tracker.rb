module ZSpec
  class Tracker
    def initialize(flaky_threshold:, sink:)
      @failure_hash_name = "flakes"
      @flaky_threshold = flaky_threshold
      @sink = sink
    end

    def flaky_specs
      @sink.hgetall(@failure_hash_name).map { |failure, message| JSON.parse(message) }
        .select { |failure| (@sink.time - failure["last_failure"].to_i) < @flaky_threshold }
        .sort_by { |failure| failure["count"] }
        .reverse
    end

    def track_failure(failures:)
      failures.map(&:id).each do |message|
        failure = JSON.parse(@sink.hget(@failure_hash_name, message) || "{\"count\":0}")
        failure.merge!({"message": message, "last_failure": @sink.time, "count": failure["count"].to_i+1 })
        @sink.hset(@failure_hash_name, message, failure.to_json)
      end
    end
  end
end
