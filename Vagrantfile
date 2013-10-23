Vagrant.configure("2") do |config|
  config.vm.hostname = "snapshot-timer"
  config.vm.box = "ri_centos_v13.5_betaRL"
  config.vm.box_url = "https://dl.dropboxusercontent.com/u/26374213/images/ri_centos_v13.5_betaRL.box"
  config.vm.network :private_network, ip: "33.33.33.10"
  config.rightscaleshim.run_list_dir = "runlists/default"
  config.rightscaleshim.shim_dir = "rightscaleshim/default"
  config.berkshelf.enabled = true
  config.vm.provision :shell, path: "../import_env.sh"
  config.vm.provision :chef_solo do |chef|
    chef.binary_path = "/opt/rightscale/sandbox/bin"
    chef.run_list = [
      # use rightscaleshim runlists
    ]
  end
end
