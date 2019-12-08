module ZSpec
  class Scheduler
    def initialize(queue:, tracker:)
      @queue   = queue
      @tracker = tracker
    end

    def schedule(args)
      enqueue(
        extract(args)
        .uniq
        .map(&method(:normalize))
        .sort_by(&method(:runtime))
        .reverse
      )
    end

    private

    def extract(args)
      configuration = ::RSpec.configuration
      ::RSpec::Core::ConfigurationOptions.new([args]).configure(configuration)
      configuration.files_to_run
    end

    def runtimes
      @runtimes ||= @tracker.all_runtimes
    end

    def runtime(example)
      runtimes[example].to_i || 0
    end

    def enqueue(examples)
      @queue.enqueue(examples)
    end

    def normalize(file)
      file.sub("#{Dir.pwd}/", "./")
    end
  end
end
