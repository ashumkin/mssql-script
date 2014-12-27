# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mssql/script/version'

Gem::Specification.new do |spec|
  spec.name          = "mssql-script"
  spec.version       = MSSQL::Script::VERSION
  spec.authors       = ["Alexey Shumkin"]
  spec.email         = ["Alex.Crezoff@gmail.com"]
  spec.summary       = %q{Manage MS SQL server DDL}
  spec.description   = %q{Bunch of tools to export MS SQL Server objects to files. Normalize DDLs. Apply DDLs to MS SQL Server.}
  spec.homepage      = "http://github.com/ashumkin/mssql-script"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "diff", "~> 0.3.6"
end
