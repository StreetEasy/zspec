require "spec_helper"

describe ZSpec::Tracker do
  describe "#track_runtime" do
    it "stores the runtime" do
      @tracker.track_runtime(@relative_file1, 100)
      expect(@state).to include(@tracker.runtimes_hash_name => { @relative_file1 => 100 })
    end
  end

  describe "#all_runtimes" do
    it "returns all runtimes" do
      @tracker.track_runtime(@relative_file1, 100)
      expect(@tracker.all_runtimes).to eq(@relative_file1 => 100)
    end
  end

  describe "#track_failures" do
    context "existing failures" do
      it "increments the faulure count" do
        @tracker.track_failures([{ id: @relative_file1 }])
        @tracker.track_failures([{ id: @relative_file1 }])
        expect(@state).to include(@tracker.failures_hash_name => {
          @relative_file1 => @failure1.merge("count" => 2).to_json
        })
      end
    end

    context "new failures" do
      it "stores the failures" do
        @tracker.track_failures([{ id: @relative_file1 }])
        expect(@state).to include(@tracker.failures_hash_name => { @relative_file1 => @failure1.to_json })
      end
    end
  end

  describe "#recent_failures" do
    it "sorts by failure count" do
      @tracker.track_failures([{ id: @relative_file1 }])
      @tracker.track_failures([{ id: @relative_file1 }])
      @tracker.track_failures([{ id: @relative_file2 }])
      expect(@tracker.recent_failures).to eq([
                                               @failure1.merge("count" => 2),
                                               @failure2
                                             ])
    end

    it "filters failures more recent than the threshold" do
      @tracker.track_failures([{ id: @relative_file1 }])
      @state[:time] = @time + @threshold
      @tracker.track_failures([{ id: @relative_file2 }])
      expect(@tracker.recent_failures).to eq([@failure2.merge("last_failure" => @state[:time])])
    end
  end
end
