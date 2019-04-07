require "thor"
require 'zspec'

ZSpec.init

module ZSpec
  class CLI < Thor
    default_task :specs
    desc "specs", ""
    def specs(args)
      ZSpec.specs(args)
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
