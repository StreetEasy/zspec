module ZSpec
  module Presenters
    class FailureListPresenter < ZSpec::Presenters::BasePresenter
      def present(results)
        super
        format_results(results)
      end

      private

      def format_results(results)
        results["failures"].each do |example|
          @failures << example
        end
      end
    end
  end
end
