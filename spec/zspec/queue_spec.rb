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
end