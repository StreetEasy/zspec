require 'rspec/core'
require 'rspec/expectations'
require 'json'

module ZSpec
  module RSpec
    def self.extract_specs(args)
      options = ::RSpec::Core::ConfigurationOptions.new(args)
      config = ::RSpec::Core::Configuration.new
      options.configure(config)
      config.files_to_run.map{|f| f.sub("#{Dir.pwd}/","") }
    end

    def self.run(spec)
      reader, writer = IO.pipe
      system("rspec", "-f", "j", "#{spec}", out: writer, err: :out)
      writer.close
      JSON.parse(reader.read)
    end
  end
end
