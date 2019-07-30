require "thor"
require 'zspec'

module ZSpec
  class CLI < Thor
    desc "queue_specs", ""
    def queue_specs(args)
      ZSpec.queue_specs(args)
    end

    desc "present", ""
    def present
      ZSpec.present
    end

    desc "work", ""
    def work
      ZSpec.work
    end

    desc "connected", ""
    def connected
      ZSpec.connected?
    end
  end
end
