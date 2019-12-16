require "zspec"
require "pry"

RSpec.configure do |c|
  c.before :each do
    @time = 1234
    @state = { time: @time }
    @expirations = {}
    @sink = ZSpec::Sink::MemorySink.new(state: @state, expirations: @expirations)

    @build_prefix = "1:queue"
    @threshold = 100
    @tracker = ZSpec::Tracker.new(sink: @sink, threshold: @threshold, build_prefix: @build_prefix, hostname: "my-host")

    @retries = 2
    @timeout = 100
    @queue = ZSpec::Queue.new(sink: @sink, build_prefix: @build_prefix, retries: @retries, timeout: @timeout)

    @scheduler = ZSpec::Scheduler.new(queue: @queue, tracker: @tracker)

    @message1 = "message1"
    @message2 = "message2"
    @result = "{}"
    @stdout = "..."
    @test_path = "spec/resources/spec"
    @file1 = "#{Dir.pwd}/#{@test_path}/sample1_spec.rb"
    @file2 = "#{Dir.pwd}/#{@test_path}/sample2_spec.rb"
    @file3 = "#{Dir.pwd}/#{@test_path}/sample3_spec.rb"
    @relative_file1 = "./#{@test_path}/sample1_spec.rb"
    @relative_file2 = "./#{@test_path}/sample2_spec.rb"
    @relative_file3 = "./#{@test_path}/sample3_spec.rb"
    @failure1 = { "count" => 1, "message" => @relative_file1, "last_failure" => @time }
    @failure2 = { "count" => 1, "message" => @relative_file2, "last_failure" => @time }
    @failure3 = { "count" => 1, "message" => @relative_file3, "last_failure" => @time }

    @raw_failure1 = { "#{@relative_file1}:count" => 1, "#{@relative_file1}:time" => @time }
    @raw_failure2 = { "#{@relative_file2}:count" => 1, "#{@relative_file2}:time" => @time }
    @raw_failure3 = { "#{@relative_file3}:count" => 1, "#{@relative_file3}:time" => @time }
  end
end
