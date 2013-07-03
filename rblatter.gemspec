# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rblatter/version'

Gem::Specification.new do |gem|
  gem.name          = "rblatter"
  gem.version       = Rblatter::VERSION
  gem.authors       = ["Edd Barrett"]
  gem.email         = ["vext01@gmail.com"]
  gem.description   = %q{ RBlatter is a ruby script which allows you to add and subtract TeXmf
subsets using the TeX Live TLPDB information.}
  gem.summary       = %q{ RBlatter is a ruby script which allows you to add and subtract TeXmf
subsets using the TeX Live TLPDB information.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
