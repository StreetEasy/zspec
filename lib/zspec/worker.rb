module ZSpec
  class Worker
    def work
      require '/app/config/application'
      ZSpec.config.queue.process_pending(1) do |spec|
        puts "running: #{spec}"
        ZSpec.config.spec_id = spec
        ZSpec.config.stdout = stdout = StringIO.new
        fork do
          run_specs(spec, stdout)
        end
        ZSpec.config.spec_id = nil
        ZSpec.config.stdout = nil
        Process.waitall
        puts "completed: #{spec}"
      end
    end

    private

    def run_specs(spec, stdout)
      options = ::RSpec::Core::ConfigurationOptions.new([
        "--backtrace", "--format", "ZSpec::Formatter", spec,
      ])
      runner = ::RSpec::Core::Runner.new(options)
      def runner.trap_interrupt() end
      runner.run($stderr, stdout)
    end
  end
end
