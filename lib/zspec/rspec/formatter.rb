module ZSpec
  module RSpec
    require 'rspec/core/formatters/base_formatter'
    class Formatter < ::RSpec::Core::Formatters::BaseFormatter
      def close(_notification)
        ZSpec.results_queue << @current_example_group.to_json
      end

      def example_group_started(notification)
        new_example_group = {description: notification.group.description, nested_groups: [], examples: []}
        @current_example_group ||= new_example_group

        if @current_example_group != new_example_group
          @current_example_group[:nested_groups] << new_example_group
          (@example_groups ||= []) << @current_example_group
        end

        @current_example_group = new_example_group
      end

      def example_group_finished(notification)
        @current_example_group = @example_groups.pop if @example_groups.any?
      end

      def example_finished(notification)
        @current_example_group[:examples] << format_example(notification.example)
      end

      def dump_summary(summary)
        @current_example_group[:summary] = {
          example_count: summary.example_count,
          failure_count: summary.failure_count,
          pending_count: summary.pending_count,
          errors_outside_of_examples_count: summary.errors_outside_of_examples_count
        }
      end

      private

      def format_example(example)
        hash = {
          :id => example.id,
          :description => example.description,
          :full_description => example.full_description,
          :status => example.execution_result.status.to_s,
          :file_path => example.metadata[:file_path],
          :line_number  => example.metadata[:line_number],
          :run_time => example.execution_result.run_time,
          :pending_message => example.execution_result.pending_message,
        }
        e = example.exception
          if e
            hash[:exception] =  {
              :class => e.class.name,
              :message => e.message,
              :backtrace => e.backtrace,
            }
          end
        hash
      end
    end

    ::RSpec::Core::Formatters.register Formatter,
      :close, :dump_summary, :example_group_started, :example_group_finished, :example_finished
  end
end

