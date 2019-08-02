module ZSpec
  module RSpec
    class Presenter
      def initialize
        ::RSpec::configuration.tty = true
        ::RSpec::configuration.color = true
        @failures = []
        @example_count = 0
        @failure_count = 0
        @pending_count = 0
        @errors_outside_of_examples_count = 0
      end

      def print_summary
        puts ""
        puts "example_count: #{@example_count}"
        puts "failure_count: #{@failure_count}"
        puts "pending_count: #{@pending_count}"
        puts "errors_outside_of_examples_count: #{@errors_outside_of_examples_count}"
        $stdout.flush
        if @failures.any?
          puts "FAILURES:"
          @failures.each do |example|
            puts ::RSpec::Core::Formatters::ConsoleCodes.wrap("#{example["description"]} " \
                              "(FAILED - #{next_failure_index})\n" \
                              "Exception - #{example["exception"]["message"] unless example["exception"].nil?}",
                              :failure)
          end
          $stdout.flush
          exit(1)
        end
      end

      def present(results)
        @example_count                    += results["summary"]["example_count"].to_i
        @failure_count                    += results["summary"]["failure_count"].to_i
        @pending_count                    += results["summary"]["pending_count"].to_i
        @errors_outside_of_examples_count += results["summary"]["errors_outside_of_examples_count"].to_i
        format_example_groups(0, results) unless results["examples"].nil?
        $stdout.flush
      end

      private

      def format_example_groups(group_level, group)
        puts group_output(group_level, group)

        group["examples"].each do |example|
          if example["status"] == "passed"
            puts passed_output(group_level+1, example)
          elsif example["status"] == "failed"
            @failures << example
            puts failure_output(group_level+1, example)
          elsif example["status"] == "pending"
            puts pending_output(group_level+1, example)
          end
        end

        group["nested_groups"].each do |nested|
          format_example_groups(group_level+1, nested)
        end
      end

      def passed_output(group_level, example)
        ::RSpec::Core::Formatters::ConsoleCodes.wrap("#{indent(group_level)}#{example["description"]}", :success)
      end

      def pending_output(group_level, example)
        ::RSpec::Core::Formatters::ConsoleCodes.wrap("#{indent(group_level)}#{example["description"]}", :pending)
      end

      def failure_output(group_level, example)
        ::RSpec::Core::Formatters::ConsoleCodes.wrap("#{indent(group_level)}#{example["description"]}", :failure)
      end

      def group_output(group_level, example)
        "#{indent(group_level)}#{example["description"]}"
      end

      def indent(group_level)
        if ENV["ZSPEC_ESCAPE_WHITESPACE"]
          '&nbsp' * group_level
        else
          '  ' * group_level
        end
      end

      def next_failure_index
        @next_failure_index ||= 0
        @next_failure_index += 1
      end
    end
  end
end
