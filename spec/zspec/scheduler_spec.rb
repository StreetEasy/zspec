require "spec_helper"

describe ZSpec::Scheduler do
  describe "#schedule" do
    before :each do
      @tracker.track_runtime(@relative_file1, 3)
      @tracker.track_runtime(@relative_file2, 2)
      @tracker.track_runtime(@relative_file3, 1)

      @scheduler.schedule(@test_path)
    end

    it "enqueues normalized files by order of runtime" do
      expect(@state).to include(@queue.pending_queue_name => [@relative_file3, @relative_file2, @relative_file1])
    end
  end
end
