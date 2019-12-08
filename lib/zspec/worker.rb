module ZSpec
  class Worker
    APPLICATION_FILE = "/app/config/application.rb".freeze

    def initialize(queue:, tracker:)
      @queue   = queue
      @tracker = tracker
    end

    def work
      require APPLICATION_FILE if File.exist? APPLICATION_FILE
      @queue.proccess_pending(1) do |spec|
        puts "running: #{spec}"
        fork do
          run_specs(spec, StringIO.new)
        end
        Process.waitall
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
