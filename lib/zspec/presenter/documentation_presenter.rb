module ZSpec
  module Presenters
    class DocumentationPresenter < ZSpec::Presenters::BasePresenter
      def present(results, stdout)
        super(results, stdout)
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
        @out.puts message(results, group_level)

        results["examples"].each do |example|
          if example["status"] == "passed"
            @out.puts passed_output(message(example, group_level + 1))
          elsif example["status"] == "failed"
            @failures << example
            @out.puts failure_output(message(example, group_level + 1))
          elsif example["status"] == "pending"
            @out.puts pending_output(message(example, group_level + 1))
          end
        end

        results["nested_groups"].each do |nested|
          format_results(nested, group_level + 1)
        end
      end
    end
  end
end
