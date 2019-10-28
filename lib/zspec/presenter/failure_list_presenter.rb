module ZSpec
  module Presenters
    class FailureListPresenter < ZSpec::Presenters::BasePresenter
      def present(results)
        super
        track_failures(results)
        track_errors_outside_of_examples(results)
      end

      private

      def track_failures(results)
        results["failures"].each do |example|
          @failures << example
        end
      end

      def track_errors_outside_of_examples(results)
        if error_count = results["summary"]["errors_outside_of_examples_count"].to_i > 0
          @errors_outside_of_examples << {
            file_path: results["summary"]["file_path"],
            error_count: error_count,
          }
        end
      end
    end
  end
end
