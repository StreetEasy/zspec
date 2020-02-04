module ZSpec
  class Worker
    APPLICATION_FILE = "/app/config/application.rb".freeze

    def initialize(queue:, tracker:)
      @queue   = queue
      @tracker = tracker
    end

    def work(args)
      require APPLICATION_FILE if File.exist? APPLICATION_FILE
      @queue.pending_queue.each do |spec|
        next if spec.nil?
        puts "running: #{spec}"
        fork do
          run_specs(spec, args, StringIO.new)
        end
        puts 'waiting for spec to finish'
        Process.waitall
        puts "spec finished: #{spec}"
      end
    end

    private

    def run_specs(spec, args, stdout)
      formatter = ZSpec::Formatter.new(
        queue: @queue, tracker: @tracker, stdout: stdout, message: spec
      )
      configuration = ::RSpec.configuration
      configuration.add_formatter(formatter)
      options = ::RSpec::Core::ConfigurationOptions.new(["--backtrace", spec] + args)
      puts options, configuration
      runner = ::RSpec::Core::Runner.new(options, configuration)
      def runner.trap_interrupt() end
      runner.run($stderr, stdout)
    end
  end
end
