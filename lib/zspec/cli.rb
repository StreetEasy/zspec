require "thor"
require "zspec"

module ZSpec
  class CLI < Thor
    desc "queue_specs", ""
    def queue_specs(*args)
      scheduler.schedule(args)
    end

    desc "present", ""
    def present
      failed = presenter.poll_results
      queue.cleanup
      tracker.cleanup
      exit(1) if failed
    end

    desc "work", ""
    def work
      worker.work
    end

    desc "connected", ""
    def connected
      redis.connected?
    end

    private

    def presenter
      @presenter ||= ZSpec::Presenter.new(
        queue: queue,
        tracker: tracker,
        display_count: presenter_display_count,
        truncate_length: presenter_truncate_length
      )
    end

    def worker
      @worker ||= ZSpec::Worker.new(
        queue: queue,
        tracker: tracker
      )
    end

    def queue
      @queue ||= ZSpec::Queue.new(
        sink: sink,
        build_prefix: build_prefix,
        timeout: queue_timeout,
        retries: queue_retries
      )
    end

    def tracker
      @tracker ||= ZSpec::Tracker.new(
        build_prefix: build_prefix,
        threshold: tracker_threshold,
        hostname: hostname,
        sink: sink
      )
    end

    def hostname
      ENV["HOSTNAME"]
    end

    def scheduler
      @scheduler ||= ZSpec::Scheduler.new(queue: queue, tracker: tracker)
    end

    def sink
      @sink ||= ZSpec::Sink::RedisSink.new(redis: redis)
    end

    def redis
      @redis ||= Redis.new(host: redis_host, port: redis_port)
    end

    def build_prefix
      "#{build_number}:queue"
    end

    def redis_host
      ENV["ZSPEC_REDIS_HOST"]
    end

    def redis_port
      ENV["ZSPEC_REDIS_PORT"]
    end

    def build_number
      ENV["ZSPEC_BUILD_NUMBER"]
    end

    def queue_timeout
      ENV["ZSPEC_QUEUE_TIMEOUT"] || 420
    end

    def queue_retries
      ENV["ZSPEC_QUEUE_RETRIES"] || 0
    end

    def presenter_display_count
      ENV["ZSPEC_PRESENTER_DISPLAY_COUNT"] || 25
    end

    def presenter_truncate_length
      ENV["ZSPEC_PRESENTER_TRUNCATE_LENGTH"] || 2_000
    end

    def tracker_threshold
      ENV["ZSPEC_TRACKER_THRESHOLD"] || 60 * 60 * 24 * 14
    end
  end
end
