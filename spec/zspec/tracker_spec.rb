require "spec_helper"

describe ZSpec::Tracker do
  describe "#cleanup" do
    it "sets expirations on the queues" do
      @tracker.cleanup
      expect(@expirations).to include(
        @tracker.current_failures_hash_name => ZSpec::EXPIRE_SECONDS
      )
    end
  end

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
        expect(@state).to include(@tracker.alltime_failures_hash_name =>
          @raw_failure1.merge("#{@relative_file1}:count" => 2)
        )
        expect(@state).to include(@tracker.current_failures_hash_name =>
          @raw_failure1.merge("#{@relative_file1}:count" => 2)
        )
      end
    end

    context "new failures" do
      it "stores the failures" do
        @tracker.track_failures([{ id: @relative_file1 }])
        expect(@state).to include(@tracker.alltime_failures_hash_name => @raw_failure1)
        expect(@state).to include(@tracker.current_failures_hash_name => @raw_failure1)
      end
    end
  end

  describe "#alltime_failures" do
    it "sorts by failure count" do
      @tracker.track_failures([{ id: @relative_file1 }])
      @tracker.track_failures([{ id: @relative_file1 }])
      @tracker.track_failures([{ id: @relative_file2 }])
      expect(@tracker.alltime_failures).to eq([
                                                @failure1.merge("count" => 2),
                                                @failure2
                                              ])
    end

    it "filters failures more recent than the threshold" do
      @tracker.track_failures([{ id: @relative_file1 }])
      @state[:time] = @time + @threshold
      @tracker.track_failures([{ id: @relative_file2 }])
      expect(@tracker.alltime_failures).to eq([
        @failure2.merge("last_failure" => @state[:time])
      ])
    end
  end

  describe "#current_failures" do
    it "sorts by failure count" do
      @tracker.track_failures([{ id: @relative_file1 }])
      @tracker.track_failures([{ id: @relative_file1 }])
      @tracker.track_failures([{ id: @relative_file2 }])
      expect(@tracker.current_failures).to eq([
                                                @failure1.merge("count" => 2),
                                                @failure2
                                              ])
    end
  end
end
