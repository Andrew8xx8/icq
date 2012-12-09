# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'icq/version'

Gem::Specification.new do |gem|
  gem.name          = "icq"
  gem.version       = Icq::VERSION
  gem.authors       = ["Andrew8xx8"]
  gem.email         = ["avk@8xx8.ru"]
  gem.description   = %q{The eventmachine-based implementation of the OSCAR protocol (AIM, ICQ)}
  gem.summary       = %q{The eventmachine-based implementation of the OSCAR protocol (AIM, ICQ)}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "happymapper"
  gem.add_runtime_dependency "eventmachine"
end
