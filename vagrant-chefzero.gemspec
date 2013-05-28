# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-chefzero/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-chefzero"
  spec.version       = Vagrant::ChefzeroPlugin::VERSION
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

  ######## From vagrant-berkshelf 1.2.0:
  # activesupport 3.2.13 contains an incompatible hard lock on i18n (= 0.6.1)
  spec.add_runtime_dependency 'activesupport', '~> 3.2', '< 3.2.13'

  spec.add_runtime_dependency 'ridley', '~> 0.12'
  spec.add_runtime_dependency 'berkshelf', '~> 1.4'

  # Explicit locks to ensure we activate the proper gem versions for Vagrant
#  spec.add_runtime_dependency "i18n", "~> 0.6.0"
#  spec.add_runtime_dependency "json", ">= 1.5.1", "< 1.8.0"
#  spec.add_runtime_dependency "net-ssh", "~> 2.6.6"
#  spec.add_runtime_dependency "net-scp", "~> 1.1.0"
  ########

  #Dependencies from vagrant.
  #Our dependencies need to be compatible with Vagrant's.
#  spec.add_dependency "childprocess", "~> 0.3.7"
#  spec.add_dependency "erubis", "~> 2.7.0"
#  spec.add_dependency "i18n", "~> 0.6.0"
#  spec.add_dependency "json", ">= 1.5.1", "< 1.8.0"
#  spec.add_dependency "log4r", "~> 1.1.9"
#  spec.add_dependency "net-ssh", "~> 2.6.6"
#  spec.add_dependency "net-scp", "~> 1.1.0"


  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
