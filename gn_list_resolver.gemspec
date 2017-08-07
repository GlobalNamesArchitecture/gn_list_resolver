# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gn_list_resolver/version"

# rubocop:disable Metrics/BlockLength:

Gem::Specification.new do |gem|
  gem.required_ruby_version = ">= 2.4"
  gem.name          = "gn_list_resolver"
  gem.version       = GnListResolver::VERSION
  gem.license       = "MIT"
  gem.authors       = ["Dmitry Mozzherin", "Alexander Myltsev"]
  gem.email         = ["dmozzherin@gmail.com"]

  gem.summary       = "Resolves a list of scientific names to names from " \
                      "a data source in GN Index"
  gem.description   = "Gem uses a checklist in a comma-separated format as " \
                      "an input, and returns back a new comma-separated " \
                      "resolved list of scientific names to one of the " \
                      "data sources from http://resolver.globalnames.org"
  gem.homepage      =
    "https://github.com/GlobalNamesArchitecture/gn_list_resolver"

  gem.files         = `git ls-files -z`.
                      split("\x0").
                      reject { |f| f.match(%r{^(test|spec|features)/}) }
  gem.bindir        = "exe"
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "biodiversity", "~> 3.1"
  gem.add_dependency "gn_uuid", "~> 0.5"
  gem.add_dependency "graphql-client", "~> 0.11.3"
  gem.add_dependency "logger-colors", "~> 1.0"
  gem.add_dependency "rest-client", "~> 2.0"
  gem.add_dependency "trollop", "~> 2.1"

  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "byebug", "~> 9.0"
  gem.add_development_dependency "coveralls", "~> 0.8"
  gem.add_development_dependency "rake", "~> 12.0"
  gem.add_development_dependency "rspec", "~> 3.2"
  gem.add_development_dependency "rubocop", "~> 0.49"
end

# rubocop:enable Metrics/BlockLength:
