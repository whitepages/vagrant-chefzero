require 'chefzero/version'

module Vagrant
  module Chefzero
    class Plugin < Vagrant.plugin("2")
      name 'chefzero'

      config('chefzero', :provisioner) do
        Config
      end

      provisioner 'chefzero' do
        Provisioner
      end

##      provider 'hostnative' do
##        Provider
##      end
    end

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

    class Config < Vagrant.plugin("2", :config)
      attr_accessor :shell_setup

      def initialize
        self.shell_setup = UNSET_VALUE
      end

      def finalize!
        shell_setup = '' if shell_setup == UNSET_VALUE
      end
    end

    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config)
        super
      end

      def configure(root_config)
      end

      def provision
        cmds = config.shell_setup.split(/\n/)
        cmds.each { |cmd| system cmd }
      end
    end

  end
end
