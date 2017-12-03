# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi_swagger_helpers/version'

Gem::Specification.new do |spec|
  spec.name          = "jsonapi_swagger_helpers"
  spec.version       = JsonapiSwaggerHelpers::VERSION
  spec.authors       = ["Lee Richmond"]
  spec.email         = ["lrichmond1@bloomberg.net"]

  spec.summary       = %q{Swagger helpers for jsonapi.org-compatible APIs}
  spec.description   = %q{Requires jsonapi_suite of libraries}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'swagger-blocks', '~> 1.3'
  # TODO: above 0.4.2
  spec.add_dependency 'jsonapi_spec_helpers', ['< 1']
  spec.add_dependency 'jsonapi_compliable', ['~> 0.10']
  spec.add_runtime_dependency 'strong_resources', '>= 0'

  spec.add_development_dependency "activesupport", ">= 4.1"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "byebug", ">= 0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
