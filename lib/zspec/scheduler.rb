module ZSpec
  class Scheduler
    def initialize(args)
      options       = ::RSpec::Core::ConfigurationOptions.new([args])
      configuration = ::RSpec::Core::Configuration.new
      def configuration.command() 'rspec' end
      options.configure(configuration)
      @files = configuration.files_to_run.uniq
    end

    def enqueue
      normalize_files!
      sort_by_longest!
      queue_specs
    end

    private

    def normalize_files!
      @files.map!{|file| file.sub("#{Dir.pwd}/","./") }
    end

    def sort_by_longest!
      prev = ::JSON.parse(ZSpec.config.previous_execution_runtimes_key.get || "{}")
      @files.sort_by!{|file| prev[file] || 0 }.reverse!
    end

    def queue_specs
      @files.each do |file|
        ZSpec.config.spec_count_key.incr
        ZSpec.config.specs_queue << file
      end
    end
  end
end
