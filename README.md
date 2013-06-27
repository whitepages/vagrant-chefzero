# Vagrant::Chefzero

A Vagrant plugin for integration with chef-zero:
https://github.com/jkeiser/chef-zero

## Installation

vagrant plugin install vagrant-chefzero

## Usage

Sample Vagrantfile:

      chef_zero_ip = '33.33.33.10'
      chef_zero_port = '8889'

      Vagrant.configure("2") do |config|
        config.ssh.max_tries = 40
        config.ssh.timeout   = 120

        config.vm.define :chefzero do |chefzero|
          chefzero.vm.network :private_network, ip: chef_zero_ip
          chefzero.vm.box = 'precise64'
          chefzero.vm.box_url = 'http://files.vagrantup.com/precise64.box'

          chefzero.vm.provision :chefzero do |cz|
            cz.ip = chef_zero_ip
            cz.port = chef_zero_port
            cz.setup do |p|
              p.import_data_bag_item(:users, :global)
              p.import_berkshelf_cookbooks
            end
          end
        end

        config.vm.define :target do |target|
          target.vm.hostname = "stuff.dev.pages"
          target.vm.network :private_network, ip: "33.33.33.20"
          target.vm.box = 'precise64'
          target.vm.box_url = 'http://files.vagrantup.com/precise64.box'

          target.vm.provision :chef_client do |chef|
            chef.chef_server_url = "http://#{chef_zero_ip}:#{chef_zero_port}"
            chef.validation_key_path = Vagrant::ChefzeroPlugin.pemfile
            chef.add_recipe "wp-vagrant"

            #The recipe we actually care about.
            chef.add_recipe "my-cookbook::server"
          end
        end
      end

When the provisioner runs, it will generate a Knife configuration file
.vagrant-chef-zero/knife.rb appropriate for interacting with the chef-zero
instance.
