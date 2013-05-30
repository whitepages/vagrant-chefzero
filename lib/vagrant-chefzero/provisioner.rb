require 'vagrant-chefzero'

module Vagrant
  module ChefzeroPlugin
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config)
        super
      end

      def configure(root_config)
        super
      end

      def provision
        FileUtils.mkdir_p(generated_path)
        install_chef_zero
        gen_knife_rb

        config.setup.call(self)
      end

      def import_data_bag_item(bag_name, item_name)
        user_ridley = ridley(user_creds)
        contents = user_ridley.data_bag.find(bag_name).item.find(item_name)

        zero_ridley = ridley(zero_creds)
        databag = zero_ridley.data_bag.find(bag_name) || zero_ridley.data_bag.create(name: bag_name)
        databag.item.find(item_name) ? databag.item.update(contents) : databag.item.create(contents)
      end

      def import_berkshelf_cookbooks(o = {})
        # path_env = o[:path] ? "BERKSHELF_PATH=#{o[:path]} " : ''
        ENV['BERKSHELF_PATH'] = generated_path
        berks(user_creds).install
        berks(zero_creds).upload
      end

      private

      def ssl_opts
        ssl_opts = { verify: config.verify_ssl }
        ssl_opts[:ca_file] = config.ca_file if config.ca_file
        ssl_opts
      end

      def ridley(creds)
        Ridley.new(creds.merge( ssl: ssl_opts ))
      end

      def berks(creds)
        BerkshelfActor.new(creds: creds, path: generated_path, verify_ssl: config.verify_ssl)
      end

      def user_creds
        c = Berkshelf::Chef::Config.instance
        {
          server_url: c[:chef_server_url],
          client_name: c[:node_name],
          client_key: c[:client_key],
        }
      end

      def zero_creds
        {
          server_url: chef_zero_uri,
          client_name: node_name,
          client_key: pemfile,
        }
      end

      def install_chef_zero
        m = MachineRunner.new(machine)

        m.do('apt-get update')

        m.test('dpkg -l ruby1.9.3 | grep ^ii > /dev/null') ||
          m.do('apt-get install -y ruby1.9.3')

        m.test('dpkg -l build-essential | grep ^ii > /dev/null') ||
          m.do('apt-get install -y build-essential')

        m.test("gem list --installed chef-zero -v #{config.version} > /dev/null") ||
          m.do("gem install chef-zero --no-rdoc --no-ri -v #{config.version}")

        m.test('ps -C chef-zero > /dev/null') ||
          m.do("chef-zero -H #{config.ip} -p #{config.port} > /vagrant/#{generated_dir}/chef-zero.log 2>&1 &")
      end

      def root_path
        machine.env.root_path
      end

      def generated_dir
        '.vagrant-chef-zero'
      end

      def generated_path
        File.join(root_path, generated_dir)
      end

      def gen_knife_rb
        File.open(File.join(generated_path, 'knife.rb'), 'w') do |f|
          f.puts(<<-EOT)
chef_server_url '#{chef_zero_uri}'
node_name '#{node_name}'
client_key '#{pemfile}'
          EOT
        end
      end

      def pemfile
        File.expand_path('vagrant-knife.pem', File.join(File.dirname(__FILE__), '..', '..'))
      end

      def chef_zero_uri
        "http://#{config.ip}:#{config.port}"
      end

      def node_name
        'vagrant-knife'
      end
    end
  end
end
