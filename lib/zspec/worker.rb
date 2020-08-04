module ZSpec
  class Worker
    APPLICATION_FILE = "/app/config/application.rb".freeze

    def initialize(queue:, tracker:, tracer:)
      @queue   = queue
      @tracker = tracker
      @tracer  = tracer
    end

    def work
      require APPLICATION_FILE if File.exist? APPLICATION_FILE
      @queue.pending_queue.each do |spec|
        next if spec.nil?
        puts "running: #{spec}"
        id = @tracer.start_spec(spec) unless @tracer.nil?
        fork do
          run_specs(spec, StringIO.new)
        end
        Process.waitall
        @tracer.end_spec(id) unless @tracer.nil?
        fail if $?.exitstatus != 0
        puts "completed: #{spec}"
      end
    end

    private

    def run_specs(spec, stdout)
      formatter = ZSpec::Formatter.new(
        queue: @queue, tracker: @tracker, stdout: stdout, message: spec
      )
      configuration = ::RSpec.configuration
      configuration.add_formatter(formatter)
      options = ::RSpec::Core::ConfigurationOptions.new(["--backtrace", spec])
      runner = ::RSpec::Core::Runner.new(options, configuration)
      def runner.trap_interrupt() end
      runner.run($stderr, stdout)
    end
  end
end
