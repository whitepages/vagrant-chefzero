require 'vagrant-chefzero/version'
require 'ridley'
require 'berkshelf'

module Vagrant
  module ChefzeroPlugin
    module Error
      class MissingProperty < StandardError; end
    end

    class Plugin < Vagrant.plugin("2")
      name 'chefzero'

      config('chefzero', :provisioner) do
        Config
      end

      provisioner 'chefzero' do
        Provisioner
      end

    end

    class Config < Vagrant.plugin("2", :config)
      attr_accessor :ip
      attr_accessor :port
      attr_accessor :setup
      attr_accessor :version
      attr_accessor :verify_ssl
      attr_accessor :ca_file

      def initialize
        self.ip         = UNSET_VALUE
        self.port       = UNSET_VALUE
        self.version    = UNSET_VALUE
        self.setup      = UNSET_VALUE
        self.ca_file    = UNSET_VALUE
        self.verify_ssl = UNSET_VALUE
      end

      def finalize!
        if self.setup == UNSET_VALUE
          self.setup = lambda {}
        end
        if self.version == UNSET_VALUE
          self.version = default_chef_zero_version
        end
        [:ip, :port].each do |req|
          raise Error::MissingProperty, "chefzero provisioner missing required property '#{req}'" unless send(req)
        end
        self.ca_file = nil if self.ca_file == UNSET_VALUE
        self.verify_ssl = false if self.verify_ssl == UNSET_VALUE
      end

      def default_chef_zero_version
        '1.0.1'
      end

      def setup(&block)
        @setup = block unless block.nil?
        @setup
      end
    end

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

      def pemfile
        File.expand_path('vagrant-knife.pem', File.join(File.dirname(__FILE__), '..'))
      end

      def chef_zero_uri
        "http://#{config.ip}:#{config.port}"
      end

      def node_name
        'vagrant-knife'
      end
    end

    class BerkshelfActor
      # Note: the Berksfile object is stateful, and must not be cached across
      # interactions with different Chef servers (e.g. install vs. upload)

      def initialize(o = {})
        @berksfile_path = o.fetch(:berksfile_path) { default_path }
        @creds = o.fetch(:creds)
        Berkshelf::Config.instance.ssl = OpenStruct.new( verify: o[:verify_ssl] )
      end

      def install
        berksfile.install(@creds)
      end

      def upload
        defaults = {
          ssl: { verify: false }, # Always false for chef-zero
          force: false,
          freeze: false,
        }
        berksfile.upload(@creds.merge(defaults))
      end

      private

      def default_path
        File.join(Dir.pwd, Berkshelf::DEFAULT_FILENAME)
      end

      def berksfile
        Berkshelf::Berksfile.from_file(@berksfile_path)
      end
    end

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
