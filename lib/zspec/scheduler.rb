module ZSpec
  class Scheduler
    def initialize(options = {})
      @sink                = options[:sink]
      @runtimes_hash_name  = "runtimes"
      @queue               = options[:queue] || ZSpec.config.queue
    end

    def schedule(args)
      files = extract(args)
        .uniq
        .map(&method(:normalize))
        .sort_by(&method(:by_runtime))
        .reverse
        .each(&method(:enqueue))
    end

    private

    def runtimes
      @runtimes ||= @sink.hgetall(@runtimes_hash_name)
    end

    def by_runtime(example)
      runtimes[example].to_i || 0
    end

    def extract(args)
      configuration = ::RSpec.configuration
      configuration.define_singleton_method(:command) { 'rspec' }
      ::RSpec::Core::ConfigurationOptions.new([args]).configure(configuration)
      configuration.files_to_run
    end

    def normalize(file)
      file.sub("#{Dir.pwd}/","./")
    end

    def enqueue(example)
      @queue.enqueue(example)
    end
  end
end
