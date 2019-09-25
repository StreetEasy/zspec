require "spec_helper"

describe ZSpec::Scheduler do
  let(:queue) do
    q = instance_double("ZSpec::Queue")
    allow(q).to receive(:enqueue).and_return("")
    q
  end

  describe "#schedule" do
    context "when presented with valid file path" do
      let(:test_spec_path) { "./spec/zspec/scheduler_spec.rb" }
      let(:scheduler) { ZSpec::Scheduler.new(queue: queue) }
      before do
        allow(scheduler).to receive(:runtimes) { { test_spec_path => 0 } }
      end

      it "returns spec file path" do
        expect(scheduler.schedule(test_spec_path)).to include(test_spec_path)
      end

      it "calls ZSpec::Queue" do
        expect(queue).to receive(:enqueue)
        scheduler.schedule(test_spec_path)
      end
    end
  end
end
