module ZSpec
  class Presenter
    def initialize
      ::RSpec::configuration.tty = true
      ::RSpec::configuration.color = true
      @failures = []
      @runtimes = {}
      @example_count = 0
      @failure_count = 0
      @pending_count = 0
      @errors_outside_of_examples_count = 0
    end

    def poll_results
      while  ZSpec.config.spec_count_key.get.to_i > 0
        while (result = ZSpec.config.results_queue.pop)
          unless result.nil?
            present(::JSON.parse(result))
            ZSpec.config.spec_count_key.decr
            ZSpec.config.results_queue.commit
          end
        end
      end
    end

    def print_summary
      puts ""
      puts "example_count: #{@example_count}"
      puts "failure_count: #{@failure_count}"
      puts "pending_count: #{@pending_count}"
      puts "errors_outside_of_examples_count: #{@errors_outside_of_examples_count}"

      puts "LONGEST RUNNING FILES:"
      @runtimes.sort_by{ |k,v| v }.reverse.take(10).each do |k,v|
        puts "#{k} took #{::RSpec::Core::Formatters::Helpers.format_duration(v)}"
      end
      $stdout.flush
      if @failures.any?
        puts "FAILURES:"
        @failures.each do |example|
          puts wrap("#{example["description"]} " \
                            "(FAILED - #{next_failure_index})\n" \
                            "Exception - #{example["exception"]["message"] unless example["exception"].nil?}",
                            :failure)
        end
        $stdout.flush
        exit(1)
      end
    end

    def save_execution_runtimes
      ZSpec.config.previous_execution_runtimes_key.set(@runtimes.sort_by{ |k,v| v }.reverse.take(30).to_h.to_json)
    end

    private

    def present(results)
      @example_count                    += results["summary"]["example_count"].to_i
      @failure_count                    += results["summary"]["failure_count"].to_i
      @pending_count                    += results["summary"]["pending_count"].to_i
      @errors_outside_of_examples_count += results["summary"]["errors_outside_of_examples_count"].to_i
      @runtimes[results["summary"]["file_path"]] = results["summary"]["duration"]
      format_example_groups(0, results) unless results["examples"].nil?
      $stdout.flush
    end

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
      wrap("#{indent(group_level)}#{example["description"]}", :success)
    end

    def pending_output(group_level, example)
      wrap("#{indent(group_level)}#{example["description"]}", :pending)
    end

    def failure_output(group_level, example)
      wrap("#{indent(group_level)}#{example["description"]}", :failure)
    end

    def wrap(message, symbol)
      ::RSpec::Core::Formatters::ConsoleCodes.wrap(message, symbol)
    end

    def group_output(group_level, example)
      "#{indent(group_level)}#{example["description"]}"
    end

    def indent(group_level)
      '  ' * group_level
    end

    def next_failure_index
      @next_failure_index ||= 0
      @next_failure_index += 1
    end
  end
end
