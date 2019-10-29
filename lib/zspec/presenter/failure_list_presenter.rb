module ZSpec
  module Presenters
    class FailureListPresenter < ZSpec::Presenters::BasePresenter
      def present(results, stdout)
        super
        track_failures(results)
      end

      private

      def track_failures(results)
        results["failures"].each do |example|
          @failures << example
        end
      end
    end
  end
end
