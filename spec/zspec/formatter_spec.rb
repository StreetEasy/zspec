require "spec_helper"

describe ZSpec::Formatter do
  before :each do
    @message = "./spec/zspec/formatter_spec.rb"
    @queue.enqueue([@message1])
    @queue.pending_queue.next

    @formatter = ZSpec::Formatter.new(
      queue: @queue, tracker: @tracker, stdout: StringIO.new, message: @message1
    )

    @exception = RuntimeError.new("ZSpec exception")
    @exception.set_backtrace []
    @failed_example = self.class.example
    @failed_example.execution_result.run_time = @time

    @start_notification = RSpec::Core::Notifications::StartNotification.new(1, @time)
    @failed_notification = RSpec::Core::Notifications::ExampleNotification.for(@failed_example)

    @example_count = 1
    @failure_count = 1
    @pending_count = 0
    @duration      = 10
    @load_time     = 0
    @errors_outside_of_examples_count = 0

    @summary_notification = RSpec::Core::Notifications::SummaryNotification.new(
      @duration, @example_count, @failure_count, @pending_count, @load_time, @errors_outside_of_examples_count
    )
  end

  context "when there are no failures" do
    before :each do
      @formatter.start(@start_notification)
      @formatter.dump_summary(@summary_notification)
      @formatter.close(@close_notification)
    end

    it "tracks the runtime" do
      expect(@state).to include(@tracker.runtimes_hash_name => { @message1 => @duration })
    end

    it "resolves the message" do
      expect(@state).to include(@queue.done_queue_name => [@message1])
    end
  end

  context "when an example fails" do
    before :each do
      @formatter.start(@start_notification)
      @formatter.example_failed(@failed_notification)
      @formatter.dump_summary(@summary_notification)
      @formatter.close(@close_notification)
    end

    it "tracks the runtime" do
      expect(@state).to include(@tracker.runtimes_hash_name => { @message1 => @duration })
    end

    it "tracks the failure" do
      expect(@state).to include(@tracker.alltime_failures_hash_name => {
        @failed_example.id.to_s => "{\"count\":1,\"message\":\"#{@failed_example.id}\",\"last_failure\":#{@time}}"
      })
    end

    it "resolves the massage" do
      expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(nil)
      expect(@state).to include(@queue.metadata_hash_name => {
        @queue.retry_key(@message1) => 1
      })
    end
  end
end
