module ZSpec
  class Worker
    def work
      require '/app/config/application'
      ZSpec.config.queue.proccess_pending(1) do |spec|
        puts "running: #{spec}"
        ZSpec.config.spec_id = spec
        fork do
          run_specs(spec)
        end
        ZSpec.config.spec_id = nil
        Process.waitall
        puts "completed: #{spec}"
      end
    end

    private

    def run_specs(spec)
      options = ::RSpec::Core::ConfigurationOptions.new([
        "--format", ZSpec.config.formatter, spec,
      ])
      runner = ::RSpec::Core::Runner.new(options)
      def runner.trap_interrupt() end
      runner.run($stderr, $stdout)
    end
  end
end
