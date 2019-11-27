require "spec_helper"

describe ZSpec::Queue do
  describe "#cleanup" do
    it "sets an expiration for the counter queue" do
      sink = instance_spy(ZSpec::Sink::RedisSink)
      prefix = "foo"

      queue = ZSpec::Queue.new(sink: sink, prefix: prefix)
      queue.cleanup

      queues = %w(count pending processing done metadata)
      queues.each do |queue|
        expect(sink).to have_received(:expire).with("foo:#{queue}", 1800)
      end
    end
  end

  describe "#enqueue" do
    it "increments the counter" do
      sink = instance_spy(ZSpec::Sink::RedisSink)
      prefix = "foo"

      queue = ZSpec::Queue.new(sink: sink, prefix: prefix)
      queue.enqueue(double(:message))

      expect(sink).to have_received(:incr).with("foo:count")
    end

    it "pushes the message to the pending queue" do
      sink = instance_spy(ZSpec::Sink::RedisSink)
      prefix = "foo"
      message = double(:message)

      queue = ZSpec::Queue.new(sink: sink, prefix: prefix)
      queue.enqueue(message)

      expect(sink).to have_received(:lpush).with("foo:pending", message)
    end
  end

  describe "#process_done" do
    context "when the counter is greater than 0" do
      context "if a message is expired" do
        it "moves the message back to pending" do
          sink = instance_spy(ZSpec::Sink::RedisSink, time: 250)
          counter_name = "foo:count"
          message = "bar"
          allow(sink).to receive(:get).with("foo:count").and_return(1, 0)
          allow(sink).to receive(:lrange).with("foo:processing", 0, -1).and_return([message])
          allow(sink).to receive(:hget).with("foo:metadata", "bar:timeout").and_return(200)

          queue = ZSpec::Queue.new(sink: sink, prefix: "foo", timeout: 10)
          queue.process_done

          expect(sink).to have_received(:lrem).with("foo:processing", message)
          expect(sink).to have_received(:rpush).with("foo:pending", message)
          expect(sink).to have_received(:hdel).with("foo:metadata", "#{message}:timeout")
        end

        it "removes the message from processing"
        it "removes the timeout key for that message"
      end

      context "if a message is not expired" do
        it "skips the message"
      end

      context "when there is a message in the done queue" do
        it "skips the message if it is nil"
        it "skips the message if it is empty"
        it "does not yield if the message is a duplicate"

        context "when there are no results for the message" do
          it "skips the message"
        end

        context "when there are results for the message" do
          it "yields the results and stdout to the block"
          it "tracks the message as processed for deduping"
          it "decrements the counter"
        end
      end
    end

    context "when the counter is 0" do
      it "stops" do
        sink = instance_spy(ZSpec::Sink::RedisSink)
        counter_name = "foo:count"
        allow(sink).to receive(:get).with("foo:count").and_return(0)

        queue = ZSpec::Queue.new(sink: sink, prefix: "foo")

        expect do |block|
          queue.process_done(&block)
        end.not_to yield_control
      end
    end
  end
end
