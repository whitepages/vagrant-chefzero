require 'vagrant-chefzero/version'

module Vagrant
  module Chefzero
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

      def initialize
        self.ip = UNSET_VALUE
        self.port = UNSET_VALUE
        self.version = UNSET_VALUE
        self.setup = UNSET_VALUE
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
      end

      def default_chef_zero_version
        '1.0.1'
      end

      def setup(&block)
        @setup = block unless block.nil?
        @setup
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

    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config)
        super
      end

      def configure(root_config)
        super
      end

      def provision
        FileUtils.mkdir_p(generated_path)
        generate_knife
        generate_config
        install_chef_zero

        config.setup.call(self)
      end

      def import_data_bag(o = {})
        o.each_pair do |bag, item|
          Dir.mktmpdir do |dir|
            fname = "#{dir}/#{bag}-#{item}.json"
            system "knife data bag show #{bag} #{item} -F json > #{fname}" # Use user's own Chef credentials
            system "knife data bag create #{bag} -c #{gen_knife}"
            system "knife data bag from file #{bag} #{fname} -c #{gen_knife}"
          end
        end
      end

      def import_berkshelf_cookbooks(o = {})
        path_env = o[:path] ? "BERKSHELF_PATH=#{o[:path]} " : ''

        system "#{path_env}berks install" # Use user's own Chef credentials
        system "#{path_env}berks upload -c #{gen_config}"
      end

      private

      def install_chef_zero
        m = MachineRunner.new(machine)
        puts "installing chef zero"

        puts "install debian packages"
        m.test('dpkg -l build-essential | grep ^ii > /dev/null') ||
          m.do('apt-get install -y build-essential')

        puts "install gems"
        m.test("gem list --installed chef-zero -v #{config.version} > /dev/null") ||
          m.do("gem install chef-zero --no-rdoc --no-ri -v #{config.version}")

        puts "start chef-zero service"
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

      def generated(basename)
        File.join(generated_path, basename)
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

      def gen_knife
        generated('knife.rb')
      end

      def gen_config
        generated('config.json')
      end

      def generate_knife
        File.open(gen_knife, 'w') do |f|
          f.puts(<<-EOT)
chef_server_url '#{chef_zero_uri}'
node_name '#{node_name}'
client_key '#{pemfile}'
          EOT
        end
      end

      def generate_config
        File.open(gen_config, 'w') do |f|
          f.puts(<<-EOT)
{
  "chef":{
    "chef_server_url":"#{chef_zero_uri}",
    "node_name":"#{node_name}",
    "client_key":"#{pemfile}"
  },
  "ssl":{
    "verify":false
  }
}
          EOT
        end
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
