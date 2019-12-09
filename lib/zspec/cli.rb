require "thor"
require "zspec"

module ZSpec
  class CLI < Thor
    def initialize(*args)
      super
      configure
    end

    desc "queue_specs", ""
    def queue_specs(*args)
      scheduler.schedule(args)
    end

    desc "present", ""
    def present
      presenter.poll_results
      queue.cleanup
      presenter.print_summary
    end

    desc "work", ""
    def work
      worker.new.work
    end

    desc "connected", ""
    def connected
      redis.connected?
    end

    private

    def configure
      ZSpec.configure do |config|
        config.sink = sink
        config.queue = queue
        config.scheduler = scheduler
        config.tracker = tracker
      end
    end

    def sink
      @sink ||= ZSpec::Sink::RedisSink.new(redis: redis)
    end

    def redis
      @redis ||= Redis.new(host: redis_host, port: redis_port)
    end

    def tracker
      @tracker ||= ZSpec::Tracker.new(
        flaky_threshold: tracker_threshold,
        sink: sink,
      )
    end

    def scheduler
      @scheduler ||= ZSpec::Scheduler.new(
        sink: sink,
      )
    end

    def queue
      @queue ||= ZSpec::Queue.new(
        sink: sink,
        queue_name: queue_name,
        timeout: queue_timeout,
        retries: queue_retries,
      )
    end

    def presenter
      @presnter ||= ZSpec::Presenter.new(
        failure_display_max: presenter_display_count,
        truncate_length: presenter_truncate_length,
      )
    end

    def worker
      @worker ||= ZSpec::Worker.new
    end

    def build_number
      ENV["ZSPEC_BUILD_NUMBER"]
    end

    def queue_timeout
      ENV["ZSPEC_QUEUE_TIMEOUT"] || 420
    end

    def queue_retries
      ENV["ZSPEC_QUEUE_RETRIES"] || 5
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

    def redis_host
      ENV["ZSPEC_REDIS_HOST"]
    end

    def redis_port
      ENV["ZSPEC_REDIS_PORT"]
    end

    def queue_name
      "#{build_number}:queue"
    end
  end
end
