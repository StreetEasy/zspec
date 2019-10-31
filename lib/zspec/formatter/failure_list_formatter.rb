module ZSpec
  module Formatters
    class FailureListFormatter < ZSpec::Formatters::BaseFormatter
      def initialize(_)
        super
        @output_hash[:failures] = []
      end

      def example_failed(failure)
        super
        @output_hash[:failures] << format_example(failure.example)
      end

      ::RSpec::Core::Formatters.register self,
        :close, :dump_summary, :stop, :example_failed
    end
  end
end
