require 'chefzero/version'

module Vagrant
  module Chefzero
    class Plugin < Vagrant.plugin("2")
      name 'chefzero'

      provisioner 'chefzero' do
        class Provisioner
          attr_accessor :root_path

          def initialize(machine, config)
            @root_path = machine.env.root_path
          end

          def configure(root_config)
            # system 'chef-zero -H 172.26.10.84 -p 8889 &'
            # system 'sleep 2'

            system(".bin/knife data bag show users global -F json > /tmp/global.json")
            system(".bin/knife data bag create users -c my-knife.rb")
            system(".bin/knife data bag from file users /tmp/global.json -c my-knife.rb")

            system 'berks install'
            system 'berks upload -c berkshelf-chef-zero.config.json'
          end

          def provision
          end
        end

        Provisioner
      end
    end
  end
end
