require "redis"
require "redis-queue"
require "zspec/rspec"
require "zspec/presenter"

module ZSpec
  def self.init
    @redis = Redis.new(host: ENV["ZSPEC_REDIS_HOST"], port: ENV["REDIS_PORT"])
    @specs_queue = Redis::Queue.new('specs', 'p_specs', redis: @redis)
    @results_queue = Redis::Queue.new('results', 'p_results', redis: @redis)
  end

  def self.connected?
    @redis.connected?
  end

  def self.specs(args)
    specs = ZSpec::RSpec.extract_specs([args])
    specs.each do |spec|
      @redis.incr "spec_count"
      @specs_queue << spec
    end
  end

  def self.present
    presenter = ZSpec::Presenter.new
    while @redis.get("spec_count").to_i > 0
      @results_queue.process(true) do |result|
        unless result.nil?
          @redis.decr "spec_count"
          presenter.present(JSON.parse(result))
        end
      end
    end
    presenter.print_summary
  end

  def self.work
    pid = fork do
      require '/app/config/application'
      while @redis.get("spec_count").to_i > 0
        @specs_queue.process(true) do |spec|
          unless spec.nil?
            puts "running #{spec}"
            result = ZSpec::RSpec.run(spec)
            @results_queue << JSON.dump(result)
          end
        end
      end
    end

    Signal.trap("INT") do
      Process.kill("KILL", pid)
    end

    Signal.trap("TERM") do
      Process.kill("KILL", pid)
    end

    Process.wait(pid)
  end
end
