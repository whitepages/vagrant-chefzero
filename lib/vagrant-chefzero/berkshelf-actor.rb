require 'vagrant-berkshelf'

module Vagrant
  module ChefzeroPlugin
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

  end
end
