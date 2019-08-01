require "redis"
require "redis-queue"
require "zspec/rspec"
require "zspec/rspec/presenter"
require 'json'

module ZSpec
  @redis          = Redis.new(host: ENV["ZSPEC_REDIS_HOST"], port: ENV["REDIS_PORT"])
  @specs_queue    = Redis::Queue.new('specs', "p_specs_#{ENV['HOSTNAME']}", redis: @redis)
  @results_queue  = Redis::Queue.new('results', 'p_results', redis: @redis)

  def self.connected?
    @redis.connected?
  end

  def self.specs_queue
    @specs_queue
  end

  def self.results_queue
    @results_queue
  end

  def self.redis
    @redis
  end

  def self.queue_specs(args)
    ZSpec::RSpec.queue_specs([args])
  end

  def self.present
    presenter = ZSpec::RSpec::Presenter.new
    while @redis.get("spec_count").to_i > 0
      @results_queue.process(true) do |result|
        unless result.nil? || result == "null"
          @redis.decr "spec_count"
          presenter.present(::JSON.parse(result))
        end
        true
      end
    end
    presenter.print_summary
  end

  def self.work
    begin
      pid = fork do
        require '/app/config/application'
        @specs_queue.process do |spec|
          unless spec.nil?
            puts "running: #{spec}"
            ZSpec::RSpec.run(spec)
            puts "completed: #{spec}"
          end
          true
        end
      end

      Signal.trap("INT") do
        Process.kill("KILL", pid)
      end

      Signal.trap("TERM") do
        Process.kill("KILL", pid)
      end

      Process.wait(pid)
    ensure
      @specs_queue.refill
    end
  end
end
