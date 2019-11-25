require 'rspec/core/formatters/base_formatter'

module ZSpec
  class Formatter < ::RSpec::Core::Formatters::BaseFormatter
    def initialize(_output)
      super
      @output_hash = {
        failures: []
      }
      @failed = false
    end

    def example_failed(failure)
      @failed = true
      @output_hash[:failures] << format_example(failure.example)
    end

    def dump_summary(summary)
      @duration = summary.duration
      if summary.errors_outside_of_examples_count.to_i > 0
        @failed = true
      end
      @output_hash[:summary] = {
        duration: summary.duration,
        load_time: summary.load_time,
        file_path: ZSpec.config.spec_id,
        example_count: summary.example_count,
        failure_count: summary.failure_count,
        pending_count: summary.pending_count,
        errors_outside_of_examples_count: summary.errors_outside_of_examples_count
      }
    end

    def close(_notification)
      ZSpec.config.queue.resolve(
        @failed,
        ZSpec.config.spec_id,
        @duration,
        @output_hash.to_json,
        ZSpec.config.stdout.string,
      )
    end

    private

    def format_example(example)
      hash = {
        id: example.id,
        description: example.description,
        full_description: example.full_description,
        status: example.execution_result.status.to_s,
        run_time: example.execution_result.run_time,
      }
      e = example.exception
      if e
        hash[:exception] =  {
          class: e.class.name,
          message: e.message,
          backtrace: e.backtrace,
        }
      end
      hash
    end

    ::RSpec::Core::Formatters.register self,
      :close, :dump_summary, :example_failed
  end
end

