require "rspec/core"
require "redis"
require "json"
require 'jira-ruby'

module ZSpec
  EXPIRE_SECONDS = 1800

  Dir[File.join(__dir__, "zspec", "*.rb")].each { |file| require file }
end
