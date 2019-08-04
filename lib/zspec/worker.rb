module ZSpec
  class Worker
    def work
      require '/app/config/application'
      ZSpec.config.specs_queue.refill
      while (spec = ZSpec.config.specs_queue.pop)
        unless spec.nil?
          puts "running: #{spec}"
          pid = fork do
            run_specs(spec)
          end
          Signal.trap("INT") do
            Process.kill("KILL", pid)
          end
          Signal.trap("TERM") do
            Process.kill("KILL", pid)
          end
          Process.wait(pid)
          ZSpec.config.specs_queue.commit
          puts "completed: #{spec}"
        end
      end
    end

    private

    def run_specs(spec)
      options = ::RSpec::Core::ConfigurationOptions.new([
        "--format", "ZSpec::RSpec::Formatter", spec,
      ])
      runner = ::RSpec::Core::Runner.new(options)
      def runner.trap_interrupt() end
      runner.run($stderr, $stdout)
    end
  end
end
