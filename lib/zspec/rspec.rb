require 'rspec/core'

module ZSpec
  module RSpec
    require 'zspec/rspec/formatter'

    def self.queue_specs(args)
      options       = ::RSpec::Core::ConfigurationOptions.new(args)
      configuration = ::RSpec::Core::Configuration.new
      def configuration.command() 'rspec' end
      options.configure(configuration)
      configuration.files_to_run.uniq.map do |file|
        ZSpec.redis.incr "spec_count"
        ZSpec.specs_queue << file.sub("#{Dir.pwd}/","")
      end
    end

    def self.run(spec)
      runner = ::RSpec::Core::Runner
      def runner.trap_interrupt() end
      runner.run(%w[--format ZSpec::RSpec::Formatter] + Array(spec), $stderr, $stdout)
    end
  end
end
