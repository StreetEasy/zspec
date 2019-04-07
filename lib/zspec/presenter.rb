module ZSpec
  class Presenter
    def initialize
      @failures = []
      @duration = 0
      @example_count = 0
      @failure_count = 0
      @pending_count = 0
      @errors_outside_of_examples_count = 0
    end

    def next_failure_index
      @next_failure_index ||= 0
      @next_failure_index += 1
    end

    def print_summary
      puts ""
      puts "total duration: #{@duration}"
      puts "example_count: #{@example_count}"
      puts "failure_count: #{@failure_count}"
      puts "pending_count: #{@pending_count}"
      puts "errors_outside_of_examples_count: #{@errors_outside_of_examples_count}"
      if @failures.any?
        puts "FAILURES:"
        @failures.each do |failure|
          puts ::RSpec::Core::Formatters::ConsoleCodes.wrap("#{failure["full_description"].strip} " \
          "Exception #{failure["exception"]}", :failure)
        end
        exit(1)
      end
    end

    def present(results)
      @duration                         += results["summary"]["duration"].to_f
      @example_count                    += results["summary"]["example_count"].to_i
      @failure_count                    += results["summary"]["failure_count"].to_i
      @pending_count                    += results["summary"]["pending_count"].to_i
      @errors_outside_of_examples_count += results["summary"]["errors_outside_of_examples_count"].to_i
      results["examples"].each do |example|
        if example["status"] == "passed"
          print ::RSpec::Core::Formatters::ConsoleCodes.wrap('.', :success)
        elsif example["status"] == "failed"
          @failures << example
          print ::RSpec::Core::Formatters::ConsoleCodes.wrap('F', :failure)
        elsif example["status"] == "pending"
          print ::RSpec::Core::Formatters::ConsoleCodes.wrap('*', :pending)
        end
      end
    end
  end
end
