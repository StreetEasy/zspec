module ZSpec
  module Formatters
    class DocumentationFormatter < ZSpec::Formatters::BaseFormatter
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

      private

      def example_groups
        @example_groups ||= []
      end

      ::RSpec::Core::Formatters.register self,
        :close, :dump_summary, :example_failed, :example_group_started, :example_group_finished, :example_finished
    end
  end
end

