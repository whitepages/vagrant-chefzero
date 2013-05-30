require 'vagrant-chefzero'

module Vagrant
  module ChefzeroPlugin

    # Adapted from the vagrant chef-client provisioner plugin
    class MachineRunner
      attr_accessor :machine

      def initialize(machine)
        self.machine = machine
      end

      def test(command)
        machine.communicate.test(command) { |type, data| show_output(type, data) }
      end

      def do(command)
        machine.communicate.sudo(command, :error_check => false) { |type, data| show_output(type, data) }
      end

      private

      def show_output(type, data)
        # Output the data with the proper color based on the stream.
        color = type == :stdout ? :green : :red

        # Note: Be sure to chomp the data to avoid newlines
        machine.env.ui.info(data.chomp, :color => color)
      end
    end

  end
end

