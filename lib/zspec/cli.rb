require "thor"
require 'zspec'

module ZSpec
  class CLI < Thor
    def initialize(*args)
      super
      configure
    end

    desc "queue_specs", ""
    def queue_specs(args)
      ZSpec::Scheduler.new(args).enqueue
    end

    desc "present", ""
    def present
      presenter = ZSpec::Presenter.new
      presenter.poll_results
      presenter.save_execution_runtimes
      cleanup
      presenter.print_summary
    end

    desc "work", ""
    def work
      ZSpec::Worker.new.work
    end

    desc "connected", ""
    def connected
      ZSpec.config.redis.connected?
    end

    private

    def cleanup
      ZSpec.config.spec_count_key.clear
    end

    def configure
      ZSpec.configure do |config|
        build_number = ENV['ZSPEC_BUILD_NUMBER']
        redis_host   = ENV["ZSPEC_REDIS_HOST"]
        redis_port   = ENV["ZSPEC_REDIS_PORT"]
        build_host   = ENV["HOSTNAME"]

        config.redis = redis = ::Redis.new(host: redis_host, port: redis_port)
        config.sink = sink = ZSpec::Sink::RedisSink.new(redis: redis)
        config.previous_execution_runtimes_key = ZSpec::Key.new(sink: sink, key_name: "previous_execution_runtimes")
        config.spec_count_key = ZSpec::Key.new(sink: sink, key_name: "#{build_number}.spec_count")
        config.specs_queue = ZSpec::Queue.new(
          sink: sink,
          queue_name: "#{build_number}.specs",
          process_queue_name: "#{build_number}.specs.#{build_host}",
        )
        config.results_queue = ZSpec::Queue.new(
          sink: sink,
          queue_name: "#{build_number}.results_queue",
        )
      end
    end
  end
end
