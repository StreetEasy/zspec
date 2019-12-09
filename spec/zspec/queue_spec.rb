require "spec_helper"

describe ZSpec::Queue do
  describe "#cleanup" do
    it "sets exiprations on the queues" do
      @queue.cleanup
      expect(@expirations).to include(
        @queue.counter_name => 1800,
        @queue.pending_queue_name => 1800,
        @queue.process_queue_name => 1800,
        @queue.done_queue_name => 1800,
        @queue.metadata_hash_name => 1800,
        @queue.workers_ready => 1800
      )
    end
  end

  describe "#enqueue" do
    it "adds an item to the pending queue" do
      @queue.enqueue([@message])
      expect(@state).to include(@queue.pending_queue_name => [@message])
    end

    it "increments the counter" do
      @queue.enqueue([@message])
      expect(@state).to include(@queue.counter_name => 1)
    end

    it "sets workers ready key as true" do
      @queue.enqueue([@message])
      expect(@state).to include(@queue.workers_ready => true)
    end
  end

  describe "#next_pending" do
    context "when there is nothing the queue" do
      it "does not yield" do
        expect { |block| @queue.next_pending(&block) }.to_not yield_control
      end

      it "does not set any metadata" do
        @queue.next_pending
        expect(@state).to_not include(@queue.metadata_hash_name => {})
      end
    end

    it "yields next item from the pending queue" do
      @queue.enqueue([@message])
      expect { |block| @queue.next_pending(&block) }.to yield_with_args(@message)
    end

    it "moves message from pending to processing" do
      @queue.enqueue([@message])
      @queue.next_pending
      expect(@state).to include(@queue.pending_queue_name => [])
    end

    it "adds timeout to metadata" do
      @queue.enqueue([@message])
      @queue.next_pending
      expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message)]).to eq(@time)
    end
  end

  describe "#resolve_message" do
    before :each do
      @queue.enqueue([@message])
      @queue.next_pending
      @queue.resolve_message(@message, @result, @stdout)
    end

    it "adds results to metadata" do
      expect(@state[@queue.metadata_hash_name][@queue.results_key(@message)]).to eq(@result)
    end

    it "adds stdout to metadata" do
      expect(@state[@queue.metadata_hash_name][@queue.stdout_key(@message)]).to eq(@stdout)
    end

    it "removes the message from processing" do
      expect(@state).to include(@queue.process_queue_name => [])
    end

    it "adds the message to done" do
      expect(@state[@queue.done_queue_name]).to eq([@message])
    end
  end

  describe "#retry_message" do
    before :each do
      @queue.enqueue([@message])
      @queue.next_pending
    end

    it "removes timeout from metadata" do
      @queue.retry_message(@message, 1)
      expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message)]).to eq(nil)
    end

    it "increments the retry count in metadata" do
      @queue.next_pending
      @queue.retry_message(@message, 1)
      expect(@state[@queue.metadata_hash_name][@queue.retry_key(@message)]).to eq(2)
    end
  end

  describe "#resolve" do
    before :each do
      @queue.enqueue([@message])
      @queue.next_pending
    end

    it "resolves the message if spec passed" do
      @queue.resolve(false, @message, @result, @stdout)
      expect(@state[@queue.done_queue_name]).to eq([@message])
    end

    it "resolves the message if it hit the retry count" do
      @queue.retry_message(@message, 2)
      @queue.resolve(true, @message, @result, @stdout)
      expect(@state[@queue.done_queue_name]).to eq([@message])
    end

    it "retries the message if it did not hit the retry count" do
      @queue.retry_message(@message, 0)
      @queue.resolve(true, @message, @result, @stdout)
      expect(@state).to include(@queue.process_queue_name => [@message])
      expect(@state).to_not include(@queue.done_queue_name)
    end
  end

  describe "#expire_processing" do
    before :each do
      @queue.enqueue([@message])
      @queue.next_pending
      @state[:time] = @time + 200
      @queue.expire_processing
    end

    it "removes message from process queue" do
      expect(@state).to include(@queue.process_queue_name => [])
    end
    it "moves message back to pending" do
      expect(@state).to include(@queue.pending_queue_name => [@message])
    end
    it "removes timeout from metadata" do
      expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message)]).to eq(nil)
    end
  end

  describe "#next_done" do
    before :each do
      @queue.enqueue([@message])
      @queue.next_pending
      @queue.resolve_message(@message, @result, @stdout)
    end

    it "removes the first message from done" do
      @queue.next_done
      expect(@state).to include(@queue.done_queue_name => [])
    end

    context "is a dupe result" do
      it "does nothing" do
        @queue.next_done
        @queue.resolve_message(@message, @result, @stdout)
        expect { |block| @queue.next_done(&block) }.not_to yield_control
      end
    end

    context "is a new result" do
      it "yields results and stdout" do
        expect { |block| @queue.next_done(&block) }.to yield_with_args(@result, @stdout)
      end

      it "sets the dedupe key in metadata" do
        @queue.next_done
        expect(@state[@queue.metadata_hash_name][@queue.dedupe_key(@message)]).to eq(true)
      end

      it "decrements the counter" do
        @queue.next_done
        expect(@state).to include(@queue.counter_name => 0)
      end
    end
  end
  describe "#proccess_done" do
    it "skips if no block given"
    context "when processing" do
      it "calls #next_done"
    end
    context "when not processing" do
      it "does not call #next_done"
    end
  end
  describe "#proccess_pending" do
    it "skips if no block given"
    it "blocks until workers are ready"
    context "when processing" do
      it "calls next pending"
    end
    context "when not processing" do
      it "does not call #next_pending"
    end
  end
end
