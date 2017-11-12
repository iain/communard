# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'communard/version'

Gem::Specification.new do |spec|
  spec.name          = "communard"
  spec.version       = Communard::VERSION
  spec.authors       = ["iain"]
  spec.email         = ["iain@iain.nl"]
  spec.summary       = %q{Adds some conventions from ActiveRecord to Sequel.}
  spec.description   = %q{Adds some conventions from ActiveRecord to Sequel.}
  spec.homepage      = "https://github.com/iain/communard"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel", "~> 5.2"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "aruba"
end
