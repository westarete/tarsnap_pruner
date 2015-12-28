# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tarsnap_pruner/version'

Gem::Specification.new do |spec|
  spec.name          = "tarsnap_pruner"
  spec.version       = TarsnapPruner::VERSION
  spec.authors       = ["Scott Woods"]
  spec.email         = ["scott@westarete.com"]

  spec.summary       = %q{A method of deleting old tarsnap backups.}
  spec.description   = %q{The Tarsnap backup service charges based on storage and bandwith. This gem provides a technique for grandfathering old backups in order to save on storage costs.}
  spec.homepage      = "https://github.com/westarete/tarsnap_pruner"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
