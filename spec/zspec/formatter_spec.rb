require "spec_helper"

describe ZSpec::Formatter do
  before :each do
    @message = "./spec/zspec/formatter_spec.rb"
    @queue.enqueue([@message1])
    @queue.proccess_pending(loop: false)

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
    @errors_outside_of_examples_count = 0

    @summary_notification = RSpec::Core::Notifications::SummaryNotification.new(
      @duration, @example_count, @failure_count, @pending_count, @errors_outside_of_examples_count
    )
  end

  context "when no failures" do
    before :each do
      @formatter.start(@start_notification)
      @formatter.dump_summary(@summary_notification)
      @formatter.close(@close_notification)
    end

    it "tracks the runtime" do
      expect(@state).to include(@tracker.runtimes_hash_name => { @message1 => @duration })
    end

    it "moves the message to the done queue" do
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

    it "removes timeout from metadata" do
      expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(nil)
    end

    it "adds retry to metadata" do
      expect(@state).to include(@queue.metadata_hash_name => {
        @queue.retry_key(@message1) => 1
      })
    end

    it "tracks the failure" do
      expect(@state).to include(@tracker.failures_hash_name => {
        @failed_example.id.to_s => "{\"count\":1,\"message\":\"#{@failed_example.id}\",\"last_failure\":#{@time}}"
      })
    end
  end
end
