require 'ostruct'
require 'rspec/core'
require 'redis'
require 'json'

module ZSpec
  def self.configure
    @config ||= OpenStruct.new
    yield(@config) if block_given?
    @config
  end

  def self.config
    @config || configure
  end

  require 'zspec/cli'
  require 'zspec/sink'
  require 'zspec/presenter'
  require 'zspec/formatter'
  require 'zspec/tracker'
  require 'zspec/queue'
  require 'zspec/scheduler'
  require 'zspec/worker'
end
