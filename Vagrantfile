Vagrant.configure("2") do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.provision :shell, :inline => <<-EOT
apt-get update
apt-get install -y ruby1.9.3
apt-get install -y build-essential
gem install chef-zero --no-rdoc --no-ri
apt-get clean
EOT
end
