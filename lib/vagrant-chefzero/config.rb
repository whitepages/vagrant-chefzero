require 'vagrant-chefzero'

module Vagrant
  module ChefzeroPlugin
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
  end
end

