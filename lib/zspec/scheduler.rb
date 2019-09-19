module ZSpec
  class Scheduler
    def initialize(options = {})
      @sink                = options[:sink]
      @runtimes_hash_name  = "runtimes"
      @examples_hash_name  = "examples"
      @runtimes            = @sink.hgetall(@runtimes_hash_name)
    end

    def schedule(args)
      files = extract(args)
        .uniq
        .map(&method(:normalize))
        .map(&method(:expand_example))
        .flatten
        .sort_by(&method(:by_runtime))
        .reverse
        .each(&method(:enqueue))
    end

    def resolve(message, runtime, ids)
      store_runtime(message, runtime)
      store_example_ids(message, ids) if runtime > 120
    end

    private

    def store_runtime(message, runtime)
      @sink.hset(@runtime_hash_name, message, runtime)
    end

    def store_example_ids(message, ids)
      @sink.hset(@examples_hash_name, sha(message), examples.to_json)
    end

    def expand_example(message)
      examples = JSON.parse(@sink.hget(@examples_hash_name, sha(message)) || "[]")
      return [message] if examples.empty?
      examples.each_slice(examples.length / 4).map do |ids|
        message + "[" + ids.join(",") + "]"
      end
    end

    def sha(message)
      Digest::SHA1.file(file_path).hexdigest
    end

    def by_runtime(example)
      @runtimes[example].to_i || 0
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
      ZSpec.config.queue.enqueue(example)
    end
  end
end
