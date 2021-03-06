module ZSpec
  class Presenter
    def initialize(queue:, tracker:, display_count:, truncate_length:, out: $stdout)
      ::RSpec.configuration.tty = true
      ::RSpec.configuration.color = true

      @queue           = queue
      @tracker         = tracker
      @display_count   = display_count
      @truncate_length = truncate_length
      @out             = out

      @failures                   = []
      @errors_outside_of_examples = []
      @runtimes                   = []
      @runtimes_by_path           = {}

      @example_count                    = 0
      @failure_count                    = 0
      @pending_count                    = 0
      @errors_outside_of_examples_count = 0
    end

    def poll_results
      @queue.done_queue.each do |results, stdout|
        next if results.nil?
        present(::JSON.parse(results), stdout)
      end
      print_summary
    end

    private

    def present(results, stdout)
      track_counts(results)
      track_errors_outside_of_examples(results, stdout)
      track_runtimes(results)
      track_runtimes_by_path(results)
      track_failures(results)
    end

    def print_summary
      @out.puts ""
      @out.puts "example_count: #{@example_count}"
      @out.puts "failure_count: #{@failure_count}"
      @out.puts "pending_count: #{@pending_count}"
      @out.puts "errors_outside_of_examples_count: #{@errors_outside_of_examples_count}"

      print_runtimes_by_path
      print_slow_specs
      print_current_flaky_specs
      print_alltime_flaky_specs
      print_failed_specs
      print_outside_of_examples

      @out.flush
      @failures.any? || @errors_outside_of_examples.any?
    end

    def print_outside_of_examples
      if @errors_outside_of_examples.any?
        @out.puts wrap("\nFIRST #{@display_count} ERRORS OUTSIDE OF EXAMPLES:", :bold)
        @errors_outside_of_examples.take(@display_count).each do |message|
          @out.puts wrap(truncated(message), :failure)
        end
      end
    end

    def print_failed_specs
      if @failures.any?
        @out.puts wrap("\nFIRST #{@display_count} FAILURES:", :bold)
        @failures.take(@display_count).each_with_index do |example, index|
          @out.puts wrap("#{example['id']}\n" \
                    "#{example['description']} (FAILED - #{index + 1})\n" \
                    "Exception - #{truncated(message_or_default(example))}\n" \
                    "Backtrace - #{truncated(backtrace_or_default(example).join("\n"))}\n",
            :failure)
        end
      end
    end

    def print_current_flaky_specs
      if @tracker.current_failures.any?
        @out.puts wrap("\nFIRST #{@display_count} FLAKY SPECS CURRENT RUN:", :bold)
        @tracker.current_failures.take(@display_count).each do |failure|
          @out.puts "#{failure['message']} failed #{failure['count']} times. "
          if failure["sequence"].any?
            @out.puts "  PREVIOUS FILES:"
            failure["sequence"].each { |spec| @out.puts "  #{spec}" }
          end
        end
      end
    end

    def print_alltime_flaky_specs
      if @tracker.alltime_failures.any?
        @out.puts wrap("\nFIRST #{@display_count} FLAKY SPECS LAST #{humanize(@tracker.threshold).upcase}:", :bold)
        @tracker.alltime_failures.take(@display_count).each do |failure|
          @out.puts "#{failure['message']} failed #{failure['count']} times. " \
            "last failure was #{humanize(Time.now.to_i - failure['last_failure'])} ago.\n"
        end
      end
    end

    def print_slow_specs
      @out.puts wrap("\n#{@display_count} SLOWEST FILES CURRENT RUN:", :bold)
      @runtimes.sort_by { |h| h[:duration] }.reverse.take(@display_count).each do |h|
        @out.puts "#{h[:file_path]} finished in #{format_duration(h[:duration])} " \
          "(file took #{format_duration(h[:load_time])} to load)\n"
      end
    end

    def print_runtimes_by_path
      @out.puts wrap("\nRUNTIMES BY PATH", :bold)
      @runtimes_by_path.sort_by{|k, v| v }.reverse.each do |k, v|
        @out.puts "#{k} finished in #{format_duration(v)}"
      end
    end

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
      unless stdout.nil? || stdout.empty? || results["summary"]["errors_outside_of_examples_count"].to_i == 0
        @errors_outside_of_examples << stdout
      end
    end

    def track_runtimes(results)
      @runtimes << {
        file_path: results["summary"]["file_path"],
        duration: results["summary"]["duration"],
        load_time: results["summary"]["load_time"]
      }
    end

    def track_runtimes_by_path(results)
      key = results.dig("summary", "file_path")&.split("/", 4)&.take(3)&.join("/") || ""
      val = results.dig("summary", "duration").to_i
      @runtimes_by_path[key] ||= 0
      @runtimes_by_path[key] += val
    end

    def humanize(secs)
      [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map { |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i} #{name}" unless n.to_i == 0
        end
      }.compact.reverse.join(" ")
    end

    def message_or_default(example)
      example.dig("exception", "message") || ""
    end

    def backtrace_or_default(example)
      example.dig("exception", "backtrace") || []
    end

    def truncated(message)
      unless message.empty?
        if message.length < @truncate_length
          message
        else
          message.slice(0..@truncate_length) + "... (truncated)"
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
