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
  require 'zspec/key'
  require 'zspec/sink'
  require 'zspec/presenter'
  require 'zspec/queue'
  require 'zspec/rspec'
  require 'zspec/scheduler'
  require 'zspec/worker'
end
