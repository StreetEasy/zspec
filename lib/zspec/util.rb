module ZSpec
  module Util
    def timeout_key(message)
      "#{message}:timeout"
    end

    def stdout_key(message)
      "#{message}:stdout"
    end

    def results_key(message)
      "#{message}:results"
    end

    def retry_key(message)
      "#{message}:retries"
    end

    def dedupe_key(message)
      "#{message}:dedupe"
    end
  end
end
