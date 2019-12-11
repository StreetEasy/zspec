require "rspec/core"
require "redis"
require "json"

module ZSpec
  Dir["./lib/zspec/*.rb"].each {|file| require file }
end
