module ZSpec
  module Presenters
    class DocumentationPresenter < ZSpec::Presenters::BasePresenter
      def present(results)
        super
        format_results(results) if results["examples"]
      end

      private

      def indent(group_level)
        "  " * group_level
      end

      def message(example, group_level)
        "#{indent(group_level)}#{example['description']}"
      end

      def passed_output(message)
        wrap(message, :success)
      end

      def pending_output(message)
        wrap(message, :pending)
      end

      def failure_output(message)
        wrap(message, :failure)
      end

      def format_results(results, group_level = 0)
        puts message(results, group_level)

        results["examples"].each do |example|
          if example["status"] == "passed"
            puts passed_output(message(example, group_level + 1))
          elsif example["status"] == "failed"
            @failures << example
            puts failure_output(message(example, group_level + 1))
          elsif example["status"] == "pending"
            puts pending_output(message(example, group_level + 1))
          end
        end

        results["nested_groups"].each do |nested|
          format_results(nested, group_level + 1)
        end
      end
    end
  end
end
