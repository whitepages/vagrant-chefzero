require 'vagrant-chefzero/version'
require 'ridley'
require 'berkshelf'

module Vagrant
  module ChefzeroPlugin
    module Error
      class MissingProperty < StandardError; end
    end
  end
end

require 'vagrant-chefzero/config'
require 'vagrant-chefzero/provisioner'
require 'vagrant-chefzero/berkshelf-actor'
require 'vagrant-chefzero/machine-runner'

module Vagrant
  module ChefzeroPlugin
    class Plugin < Vagrant.plugin("2")

      name 'chefzero'

      config('chefzero', :provisioner) do
        Config
      end

      provisioner 'chefzero' do
        Provisioner
      end

    end
  end
end


## Future enhancement:
##    class Plugin < Vagrant.plugin("2")
##      name 'hostnative'
##      provider 'hostnative' do
##        Provider
##      end
##    end
##    class Provider < Vagrant.plugin("2", :provider)
##      def initialize(machine)
##        super
##      end
##
##      def action(action_name)
##      end
##
##      private
##      def up; end
##      def halt; end
##      def destroy; end
##
##    end
