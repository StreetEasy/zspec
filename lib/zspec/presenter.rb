module ZSpec
  class Presenter
    def initialize(failure_display_max:)
      ::RSpec::configuration.tty = true
      ::RSpec::configuration.color = true
      @failures = []
      @errors_outside_of_examples = []
      @runtimes = []
      @example_count = 0
      @failure_count = 0
      @failure_display_max = failure_display_max
      @pending_count = 0
      @errors_outside_of_examples_count = 0
    end

    def poll_results
      ZSpec.config.queue.proccess_done(1) do |results, stdout|
        present(::JSON.parse(results), stdout)
      end
    end

    def present(results, stdout)
      track_counts(results)
      track_errors_outside_of_examples(results, stdout)
      track_runtimes(results)
      track_failures(results)
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
      ZSpec.config.tracker.flaky_specs.take(@failure_display_max).each do |failure|
        puts "#{failure["message"]} failed #{failure["count"]} times. " \
          "last failure was #{humanize(Time.now.to_i - failure["last_failure"])} ago.\n"
      end

      $stdout.flush

      if @failures.any?
        puts "FIRST #{@failure_display_max} FAILURES:"
        @failures.take(@failure_display_max).each_with_index do |example, index|
          puts wrap("#{example["id"]}\n" \
                    "#{example["description"]} (FAILED - #{index+1})\n" \
                    "Exception - #{truncated(message_or_default(example))}\n" \
                    "Backtrace - #{truncated(backtrace_or_default(example).join("\n"))}\n",
                    :failure)
        end
      end

      if @errors_outside_of_examples.any?
        puts "FIRST #{@failure_display_max} ERRORS OUTSIDE OF EXAMPLES:"
        @errors_outside_of_examples.take(@failure_display_max).each do |message|
          puts wrap(truncated(message), :failure)
        end
      end

      if @failures.any? || @errors_outside_of_examples.any?
        $stdout.flush
        exit(1)
      end
    end

    private

    def track_failures(results)
      results["failures"].each do |example|
        @failures << example
      end
    end

    def track_counts(results)
      @example_count                    += results["summary"]["example_count"].to_i
      @failure_count                    += results["summary"]["failure_count"].to_i
      @pending_count                    += results["summary"]["pending_count"].to_i
      @errors_outside_of_examples_count += results["summary"]["errors_outside_of_examples_count"].to_i
    end

    def track_errors_outside_of_examples(results, stdout)
      @errors_outside_of_examples << stdout unless stdout.nil? || stdout.empty? || results["summary"]["errors_outside_of_examples_count"].to_i == 0
    end

    def track_runtimes(results)
      @runtimes << {
        file_path: results["summary"]["file_path"],
        duration:  results["summary"]["duration"],
        load_time: results["summary"]["load_time"],
      }
    end

    def humanize(secs)
      [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i} #{name}" unless n.to_i==0
        end
      }.compact.reverse.join(' ')
    end

    def message_or_default(example)
      example.dig("exception", "message") || ""
    end

    def backtrace_or_default(example)
      example.dig("exception", "backtrace") || []
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
