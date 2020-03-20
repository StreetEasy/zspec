require "rspec/core/formatters/base_formatter"

module ZSpec
  class Formatter < ::RSpec::Core::Formatters::BaseFormatter
    def initialize(queue:, tracker:, stdout:, message:)
      super
      @failures    = []
      @failed      = false
      @message     = message
      @queue       = queue
      @tracker     = tracker
      @stdout      = stdout
      @start_time  = Time.now
    end

    def example_group_started(notification)
      new_example_group = {description: notification.group.description, nested_groups: [], examples: []}
      unless @output_hash.empty?
        @output_hash[:nested_groups] << new_example_group
        example_groups << @output_hash
      end
      @output_hash = new_example_group
    end

    def example_group_finished(notification)
      @output_hash = example_groups.pop if example_groups.any?
    end

    def example_finished(notification)
      @output_hash[:examples] << format_example(notification.example)
    end

    def example_failed(failure)
      @failed = true
      @failures << format_example(failure.example)
    end

    def dump_summary(summary)
      @duration = summary.duration
      # only set to true if there is a failure, otherwise it will override the failures from example_failed
      @failed   = true if summary.errors_outside_of_examples_count.to_i > 0
      @output_hash[:failures] = @failures
      @output_hash[:summary] = format_summary(summary)
    end

    def close(_notification)
      @queue.resolve(
        @failed,
        @message,
        @output_hash.to_json,
        @stdout.string
      )
      @tracker.track_runtime(@message, @duration)
      @tracker.track_failures(@failures) if @failed
      @tracker.track_sequence(@message)
    end

    private

    def format_summary(summary)
      {
        duration: summary.duration,
        load_time: summary.load_time,
        file_path: @message,
        example_count: summary.example_count,
        failure_count: summary.failure_count,
        pending_count: summary.pending_count,
        errors_outside_of_examples_count: summary.errors_outside_of_examples_count
      }
    end

    def format_example(example)
      hash = {
        id: example.id,
        description: example.description,
        full_description: example.full_description,
        status: example.execution_result.status.to_s,
        run_time: example.execution_result.run_time
      }
      e = example.exception
      if e
        hash[:exception] = {
          class: e.class.name,
          message: e.message,
          backtrace: e.backtrace
        }
      end
      hash
    end

    ::RSpec::Core::Formatters.register self,
        :close, :dump_summary, :example_failed, :example_group_started, :example_group_finished, :example_finished
  end
end
