require "spec_helper"

describe ZSpec::Queue do
  describe "#cleanup" do
    it "sets expirations on the queues" do
      @queue.cleanup
      expire_seconds = 1800
      expect(@expirations).to include(
        @queue.counter_name => expire_seconds,
        @queue.pending_queue_name => expire_seconds,
        @queue.processing_queue_name => expire_seconds,
        @queue.done_queue_name => expire_seconds,
        @queue.metadata_hash_name => expire_seconds,
        @queue.workers_ready_key_name => expire_seconds
      )
    end
  end

  describe "#enqueue" do
    it "adds an item to the pending queue" do
      @queue.enqueue([@message1])
      expect(@state).to include(@queue.pending_queue_name => [@message1])
    end

    it "increments the counter key" do
      @queue.enqueue([@message1])
      expect(@state).to include(@queue.counter_name => 1)
    end

    it "sets workers_ready key as true" do
      @queue.enqueue([@message1])
      expect(@state).to include(@queue.workers_ready_key_name => true)
    end
  end

  describe "#next_pending" do
    context "when there are no messages in the pending queue" do
      it "does not yield" do
        expect { |block| @queue.next_pending(&block) }.to_not yield_control
      end

      it "does not set anything in the metadata hash" do
        @queue.next_pending
        expect(@state).to_not include(@queue.metadata_hash_name => {})
      end
    end

    context "when there are messages in the pending queue" do
      before :each do
        @queue.enqueue([@message1])
      end

      it "yields the next item from the pending queue" do
        expect { |block| @queue.next_pending(&block) }.to yield_with_args(@message1)
      end

      it "removes the message from the pending queue" do
        @queue.next_pending
        expect(@state).to include(@queue.pending_queue_name => [])
      end

      it "moves the message to the processing queue" do
        @queue.next_pending
        expect(@state).to include(@queue.processing_queue_name => [@message1])
      end

      it "adds a timeout to the metadata hash" do
        @queue.next_pending
        expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(@time)
      end
    end
  end

  describe "#next_done" do
    context "when there is an expired message in the processing queue" do
      before :each do
        @queue.enqueue([@message1])
        @queue.next_pending
        @state[:time] = @time + 200
        @queue.next_done
      end

      it "removes the message from the processing queue" do
        expect(@state).to include(@queue.processing_queue_name => [])
      end

      it "moves the message back to the pending queue" do
        expect(@state).to include(@queue.pending_queue_name => [@message1])
      end

      it "removes the timeout from the metadata hash" do
        expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(nil)
      end
    end

    context "when there are no messages in the done queue" do
      it "does not yield anything" do
        expect { |block| @queue.next_done(&block) }.to_not yield_control
      end
    end

    context "when there are messages in the done queue" do
      before :each do
        @queue.enqueue([@message1])
        @queue.resolve(false, @message1, @result, @stdout)
      end

      it "removes the next message from the done queue" do
        @queue.process_done
        expect(@state).to include(@queue.done_queue_name => [])
      end

      context "when the message was already seen" do
        it "does not yield anything" do
          @queue.next_done
          @queue.resolve(false, @message1, @result, @stdout)
          expect { |block| @queue.next_done(&block) }.not_to yield_control
        end
      end

      context "when the message was not already seen" do
        it "yields the results and stdout" do
          expect { |block| @queue.next_done(&block) }.to yield_with_args(@result, @stdout)
        end

        it "sets the dedupe key in the metadata hash" do
          @queue.process_done
          expect(@state[@queue.metadata_hash_name][@queue.dedupe_key(@message1)]).to eq(true)
        end

        it "decrements the counter key" do
          @queue.process_done
          expect(@state).to include(@queue.counter_name => 0)
        end
      end
    end
  end

  describe "#resolve" do
    before :each do
      @queue.enqueue([@message1])
      @queue.next_pending
    end

    context "when the spec failed" do
      context "when the spec did not hit the retry limit" do
        it "removes the timeout from the metadata hash" do
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(nil)
        end

        it "increments the retry count in the metadata hash" do
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state[@queue.metadata_hash_name][@queue.retry_key(@message1)]).to eq(1)
        end

        it "keeps the message in the processing queue" do
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state).to include(@queue.processing_queue_name => [@message1])
        end
      end

      context "when the spec hit the retry limit" do
        it "moves the message to the done queue" do
          @state[@queue.metadata_hash_name][@queue.retry_key(@message1)] = 2
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state[@queue.done_queue_name]).to eq([@message1])
        end
      end
    end

    context "when the spec passed" do
      before :each do
        @queue.resolve(false, @message1, @result, @stdout)
      end

      it "adds the results to the metadata hash" do
        expect(@state[@queue.metadata_hash_name][@queue.results_key(@message1)]).to eq(@result)
      end

      it "adds the stdout to the metadata hash" do
        expect(@state[@queue.metadata_hash_name][@queue.stdout_key(@message1)]).to eq(@stdout)
      end

      it "removes the message from the processing queue" do
        expect(@state).to include(@queue.processing_queue_name => [])
      end

      it "adds the message to done" do
        expect(@state).to include(@queue.done_queue_name => [@message1])
      end
    end
  end
end
