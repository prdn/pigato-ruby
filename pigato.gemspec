# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pigato/version'

Gem::Specification.new do |spec|
  spec.name          = "pigato"
  spec.version       = Pigato::VERSION
  spec.authors       = ["Paolo Ardoino"]
  spec.email         = ["paolo.ardoino@gmail.com"]

  spec.summary       = %q{PIGATO-RUBY}
  spec.description   = %q{PIGATO-RUBY}
  spec.homepage      = "https://github.com/prdn/pigato"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "rbczmq", "~> 1.7.8"
  spec.add_runtime_dependency "oj", "~> 2.2.0"
end
