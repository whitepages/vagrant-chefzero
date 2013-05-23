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
      attr_accessor :chef_zero_ip
      attr_accessor :chef_zero_port
      attr_accessor :setup

      def initialize
        self.chef_zero_ip = UNSET_VALUE
        self.chef_zero_port = UNSET_VALUE
        self.setup = UNSET_VALUE
      end

      def finalize!
        if setup == UNSET_VALUE
          setup = lambda {}
        end
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
      end

      def provision
        FileUtils.mkdir_p(generated_dir)
        generate_knife
        generate_config

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
        if o[:path]
          system "BERKSHELF_PATH=#{o[:path]} berks install" # Use user's own Chef credentials
          system "BERKSHELF_PATH=#{o[:path]} berks upload -c #{gen_config}"
        else
          system "berks install"
          system "berks upload -c #{gen_config}"
        end
      end

      private

      # Must be on host -- depends on user's credentials
      # knife data bag show users global -F json > gen-global.json
      # berks install --path vendor/cookbooks
      # # Could be on guest, if berks had a new-enough Ruby
      # knife data bag create users -c gen-knife.rb
      # knife data bag from file users gen-global.json -c gen-knife.rb
      # BERKSHELF_PATH=vendor/cookbooks berks upload -c gen-config.json

      def root_path
        machine.env.root_path
      end

      def generated_dir
        File.join(root_path, '.vagrant-chef-zero')
      end

      def generated(basename)
        File.join(generated_dir, basename)
      end

      def pemfile
        File.expand_path('vagrant-knife.pem', File.join(File.dirname(__FILE__), '..'))
      end

      def chef_zero_uri
        "http://#{config.chef_zero_ip}:#{config.chef_zero_port}"
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
