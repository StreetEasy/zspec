require "zspec"
require "pry"

RSpec.configure do |c|
  c.before :each do
    @time = 1234
    @state = { time: @time }
    @expirations = {}
    @sink = ZSpec::Sink::MemorySink.new(state: @state, expirations: @expirations)

    @threshold = 100
    @tracker = ZSpec::Tracker.new(sink: @sink, threshold: @threshold)

    @queue_name = "1:queue"
    @retries = 2
    @timeout = 100
    @queue = ZSpec::Queue.new(sink: @sink, queue_name: @queue_name, retries: @retries, timeout: @timeout)

    @scheduler = ZSpec::Scheduler.new(queue: @queue, tracker: @tracker)

    @message = "message"
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
    @key1 = "key1"
    @key2 = "key2"
    @key3 = "key3"
    @val1 = "val1"
    @val2 = "val2"
    @val3 = "val3"
  end
end
