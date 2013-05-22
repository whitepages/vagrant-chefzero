# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chefzero/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-chefzero"
  spec.version       = Vagrant::Chefzero::VERSION
  spec.authors       = ["Jack Foy"]
  spec.email         = ["jfoy@whitepages.com"]
  spec.description   = %q{Vagrant chef-zero provisioner plugin}
  spec.summary       = %q{Ease use of chef-zero in the Vagrant provisioning lifecycle}
  spec.homepage      = "http://github.dev.pages/ait/vagrant-chefzero"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
