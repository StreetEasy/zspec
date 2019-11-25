require "thor"
require 'zspec'
require 'active_support/inflector'

module ZSpec
  class CLI < Thor
    def initialize(*args)
      super
      configure
    end

    desc "queue_specs", ""
    def queue_specs(*args)
      ZSpec.config.scheduler.schedule(args)
    end

    desc "present", ""
    def present
      presenter = ZSpec::Presenter.new(
        failure_display_max: failure_display_max,
        truncate_length: truncate_length,
      )
      presenter.poll_results
      cleanup
      presenter.print_summary
    end

    desc "work", ""
    def work
      ZSpec::Worker.new.work
    end

    desc "connected", ""
    def connected
      redis.connected?
    end

    private

    def configure
      ZSpec.configure do |config|
        config.sink = sink
        config.queue = ZSpec::Queue.new(
          sink: sink,
          queue_name: "#{build_number}:queue",
          timeout: timeout,
          retries: retries,
        )
        config.scheduler = ZSpec::Scheduler.new(
          sink: sink,
        )
        config.tracker = ZSpec::Tracker.new(
          flaky_threshold: flaky_threshold,
          sink: sink,
        )
      end
    end

    def cleanup
      ZSpec.config.queue.cleanup
    end

    def build_number
      ENV['ZSPEC_BUILD_NUMBER']
    end

    def timeout
      ENV["ZSPEC_TIMEOUT"] || 420
    end

    def retries
      ENV["ZSPEC_RETRIES"] || 0
    end

    def failure_display_max
      ENV["ZSPEC_FAILURE_DISPLAY_MAX"] || 25
    end

    def truncate_length
      ENV["ZSPEC_TRUNCATE_LENGTH"] || 2_000
    end

    def flaky_threshold
      ENV["ZSPEC_FLAKY_THRESHOLD"] || 60 * 60 * 24 * 14
    end

    def sink
      ZSpec::Sink::RedisSink.new(redis: redis)
    end

    def redis
      Redis.new(host: ENV["ZSPEC_REDIS_HOST"], port: ENV["ZSPEC_REDIS_PORT"])
    end
  end
end
