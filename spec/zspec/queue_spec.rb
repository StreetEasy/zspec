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
        @queue.workers_ready_key_name => 1800
      )
    end
  end

  describe "#enqueue" do
    it "adds an item to the pending queue" do
      @queue.enqueue([@message1])
      expect(@state).to include(@queue.pending_queue_name => [@message1])
    end

    it "increments the counter" do
      @queue.enqueue([@message1])
      expect(@state).to include(@queue.counter_name => 1)
    end

    it "sets workers ready key as true" do
      @queue.enqueue([@message1])
      expect(@state).to include(@queue.workers_ready_key_name => true)
    end
  end

  describe "#proccess_pending" do
    context "when not processing" do
      it "does not yield" do
        expect { |block| @queue.proccess_pending(loop: false, &block) }.to_not yield_control
      end

      it "does not set any metadata" do
        @queue.proccess_pending(loop: false)
        expect(@state).to_not include(@queue.metadata_hash_name => {})
      end
    end

    context "when processing" do
      before :each do
        @queue.enqueue([@message1])
      end

      it "blocks until workers are ready"

      it "yields next item from the pending queue" do
        expect { |block| @queue.proccess_pending(loop: false, &block) }.to yield_with_args(@message1)
      end

      it "removes message from pending" do
        @queue.proccess_pending(loop: false)
        expect(@state).to include(@queue.pending_queue_name => [])
      end

      it "moves message to processing" do
        @queue.proccess_pending(loop: false)
        expect(@state).to include(@queue.process_queue_name => [@message1])
      end

      it "adds timeout to metadata" do
        @queue.proccess_pending(loop: false)
        expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(@time)
      end
    end
  end

  describe "#resolve" do
    before :each do
      @queue.enqueue([@message1])
      @queue.proccess_pending(loop: false)
    end

    context "when the spec failed" do
      context "when the spec did not hit the retry limit" do
        it "removes timeout from metadata" do
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(nil)
        end

        it "increments the retry count in metadata" do
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state[@queue.metadata_hash_name][@queue.retry_key(@message1)]).to eq(1)
        end

        it "keeps the message in the processing queue" do
          @queue.resolve(true, @message1, @result, @stdout)
          expect(@state).to include(@queue.process_queue_name => [@message1])
        end
      end

      context "when the spec hit the retry limit" do
        it "resolves the message" do
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

      it "adds results to metadata" do
        expect(@state[@queue.metadata_hash_name][@queue.results_key(@message1)]).to eq(@result)
      end

      it "adds stdout to metadata" do
        expect(@state[@queue.metadata_hash_name][@queue.stdout_key(@message1)]).to eq(@stdout)
      end

      it "removes the message from processing" do
        expect(@state).to include(@queue.process_queue_name => [])
      end

      it "adds the message to done" do
        expect(@state).to include(@queue.done_queue_name => [@message1])
      end
    end
  end

  describe "#process_done" do
    context "when there is an expired message in the queue" do
      before :each do
        @queue.enqueue([@message1])
        @queue.proccess_pending(loop: false)
        @state[:time] = @time + 200
        @queue.process_done(loop: false)
      end

      it "removes message from process queue" do
        expect(@state).to include(@queue.process_queue_name => [])
      end

      it "moves message back to pending" do
        expect(@state).to include(@queue.pending_queue_name => [@message1])
      end

      it "removes timeout from metadata" do
        expect(@state[@queue.metadata_hash_name][@queue.timeout_key(@message1)]).to eq(nil)
      end
    end

    context "when not processing" do
      it "does not yield" do
        expect { |block| @queue.process_done(&block) }.to_not yield_control
      end
    end

    context "when processing" do
      before :each do
        @queue.enqueue([@message1])
        @queue.resolve(false, @message1, @result, @stdout)
      end

      it "removes the first message from done" do
        @queue.process_done
        expect(@state).to include(@queue.done_queue_name => [])
      end

      context "when the message was already resolved" do
        it "does nothing" do
          @queue.process_done
          @queue.resolve(false, @message1, @result, @stdout)
          expect { |block| @queue.process_done(&block) }.not_to yield_control
        end
      end

      context "is a new result" do
        it "yields results and stdout" do
          expect { |block| @queue.process_done(&block) }.to yield_with_args(@result, @stdout)
        end

        it "sets the dedupe key in metadata" do
          @queue.process_done
          expect(@state[@queue.metadata_hash_name][@queue.dedupe_key(@message1)]).to eq(true)
        end

        it "decrements the counter" do
          @queue.process_done
          expect(@state).to include(@queue.counter_name => 0)
        end
      end
    end
  end
end
