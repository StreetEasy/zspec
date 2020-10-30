lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "zspec/version"

Gem::Specification.new do |spec|
  spec.name          = "zspec"
  spec.version       = ZSpec::VERSION

  spec.authors       = ["Seth Pollack"]
  spec.email         = ["seth@sethpollack.net"]

  spec.summary       = "rspec runner"
  spec.description   = "parallel rspec runner"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.bindir = "bin"
  spec.executables = ["zspec"]
  spec.require_paths = ["lib"]

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.add_dependency "redis"
  spec.add_dependency "thor"
  spec.add_dependency 'activesupport'
  spec.add_dependency 'multipart-post'
  spec.add_dependency 'oauth'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "pry", "~> 0.12.2"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rspec"
end
