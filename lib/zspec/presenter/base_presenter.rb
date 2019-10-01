module ZSpec
  module Presenters
    class BasePresenter
      def initialize
        ::RSpec::configuration.tty = true
        ::RSpec::configuration.color = true
        @failures = []
        @runtimes = []
        @example_count = 0
        @failure_count = 0
        @pending_count = 0
        @errors_outside_of_examples_count = 0
      end

      def poll_results
        ZSpec.config.queue.proccess_done(1) do |results|
          present(::JSON.parse(results))
        end
      end

      def present(results)
        @example_count                    += results["summary"]["example_count"].to_i
        @failure_count                    += results["summary"]["failure_count"].to_i
        @pending_count                    += results["summary"]["pending_count"].to_i
        @errors_outside_of_examples_count += results["summary"]["errors_outside_of_examples_count"].to_i
        @runtimes << {
          file_path: results["summary"]["file_path"],
          duration:  results["summary"]["duration"],
          load_time: results["summary"]["load_time"],
        }
      end

      def print_summary
        puts ""
        puts "example_count: #{@example_count}"
        puts "failure_count: #{@failure_count}"
        puts "pending_count: #{@pending_count}"
        puts "errors_outside_of_examples_count: #{@errors_outside_of_examples_count}"

        puts "10 SLOWEST FILES:"
        @runtimes.sort_by{ |h| h[:duration] }.reverse.take(10).each do |h|
          puts "#{h[:file_path]} finished in #{format_duration(h[:duration])} " \
               "(file took #{format_duration(h[:load_time])} to load)\n"
        end


        puts "FLAKY SPECS:"
        puts ZSpec.config.queue.flaky_specs
        ZSpec.config.queue.flaky_specs.take(ZSpec.config.failure_count).each do |failure|
          puts "#{failure[:message]} failed #{failure[:count]} times. " \
               "last failure was #{humanize(failure[:last_failure])} ago.\n"
        end

        $stdout.flush

        if @failures.any?
          puts "FIRST #{ZSpec.config.failure_count} FAILURES:"
          @failures.take(ZSpec.config.failure_count).each_with_index do |example, index|
            puts wrap("#{example["id"]}\n" \
                      "#{example["description"]} (FAILED - #{index+1})\n" \
                      "Exception - #{truncated(message_or_default(example))}\n" \
                      "Backtrace - #{truncated(backtrace_or_default(example).join("\n"))}\n",
                      :failure)
          end
          $stdout.flush
          exit(1)
        end

        if @errors_outside_of_examples_count > 0
          exit(1)
        end
      end

      private

      def humanize(secs)
        [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map{ |count, name|
          if secs > 0
            secs, n = secs.divmod(count)
            "#{n.to_i} #{name}" unless n.to_i==0
          end
        }.compact.reverse.join(' ')
      end

      def message_or_default(example)
        example["exception"].nil? ? "" : example["exception"]["message"]
      end

      def backtrace_or_default(example)
        example["exception"].nil? ? "" : example["exception"]["backtrace"]
      end

      def truncated(message)
        max_length = ZSpec.config.truncate_length
        unless message.empty?
          if message.length < max_length
            message
          else
            message.slice(0..max_length) + '... (truncated)'
          end
        end
      end

      def format_duration(duration)
        ::RSpec::Core::Formatters::Helpers.format_duration(duration)
      end

      def wrap(message, symbol)
        ::RSpec::Core::Formatters::ConsoleCodes.wrap(message, symbol)
      end
    end
  end
end
