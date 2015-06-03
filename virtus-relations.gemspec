# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'virtus/relations/version'

Gem::Specification.new do |spec|
  spec.name          = 'virtus-relations'
  spec.version       = Virtus::Relations::VERSION
  spec.authors       = ['Simeon Manolov']
  spec.email         = ['s.manolloff@gmail.com']
  spec.summary       = %q{Relations for Virtus models}
  spec.homepage      = 'https://github.com/smanolloff/virtus-relations'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'virtus', '~> 1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'pry-byebug', '~> 3.1'
  spec.add_development_dependency 'activesupport', '~> 4.2'
end
