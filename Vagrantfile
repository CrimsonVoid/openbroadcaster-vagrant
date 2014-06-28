# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Pull from https://vagrantcloud.com/ubuntu/trusty64
  config.vm.box = "ubuntu/trusty64"

  config.vm.network :forwarded_port, guest: 80, host: 8080

  # Share folders for salt
  config.vm.synced_folder "salts/srv/", "/srv"

  config.vm.provision :salt do |salt|
    salt.minion_config = "salts/minion"
    salt.run_highstate = true

    salt.colorize  = true
    # salt.verbose   = true
    # salt.log_level = "debug"
  end
end
