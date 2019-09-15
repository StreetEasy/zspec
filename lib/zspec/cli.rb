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
      presenter = ZSpec.config.presenter.constantize.new
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
        config.presenter = presenter
        config.formatter = formatter
        config.sink = sink
        config.queue = ZSpec::Queue.new(
          sink: sink,
          queue_name: "#{build_number}:queue",
          timeout: timeout,
          shutdown: shutdown,
          retries: retries,
        )
        config.scheduler = ZSpec::Scheduler.new(
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

    def formatter
      ENV["ZSPEC_FORMATTER"] || "ZSpec::Formatters::FailureListFormatter"
    end

    def presenter
      ENV["ZSPEC_PRESENTER"] || "ZSpec::Presenters::FailureListPresenter"
    end

    def timeout
      ENV["ZSPEC_TIMEOUT"] || 420
    end

    def shutdown
      ENV["ZSPEC_SHUTDOWN"] || 10
    end

    def retries
      ENV["ZSPEC_RETRIES"] || 0
    end

    def sink
      ZSpec::Sink::RedisSink.new(redis: redis)
    end

    def redis
      Redis.new(host: ENV["ZSPEC_REDIS_HOST"], port: ENV["ZSPEC_REDIS_PORT"])
    end
  end
end
