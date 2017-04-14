ANSIBLE_CONTROL_MACHINE_NAME = "deimos"
DNSMASQ_MACHINE_NAME = "europa"
DOMAIN = ".ferrari.home"
INTNET_NAME = "ferrari.home.network"
NETWORK_TYPE_DHCP = "dhcp"
NETWORK_TYPE_STATIC_IP = "static_ip"
SUBNET_MASK = "255.255.0.0"

home_lab = {
  ANSIBLE_CONTROL_MACHINE_NAME + DOMAIN => {
    :autostart => false,
    :box => "boxcutter/ubuntu1604",
    :cpus => 2,
    :mac_address => "5CA1AB1E0001",
    :mem => 512,
    :net_auto_config => false,
    :net_type => NETWORK_TYPE_DHCP,
    :show_gui => true
  },
  DNSMASQ_MACHINE_NAME + DOMAIN => {
    :autostart => true,
    :box => "boxcutter/ubuntu1604",
    :cpus => 1,
    :mac_address => "5CA1AB1E0002",
    :mem => 512,
    :ip => "192.168.0.5",
    :net_auto_config => true,
    :net_type => NETWORK_TYPE_STATIC_IP,
    :subnet_mask => SUBNET_MASK,
    :show_gui => false
  },
  "pluto" + DOMAIN => {
    :autostart => false,
    :box => "clink15/pxe",
    :cpus => 1,
    :mac_address => "5CA1AB1E0003",
    :mem => 512,
    :net_auto_config => false,
    :net_type => NETWORK_TYPE_DHCP,
    :show_gui => true
  }
}

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  home_lab.each do |(hostname, info)|
    config.vm.define hostname, autostart: info[:autostart] do |host|
      host.vm.box = "#{info[:box]}"
      host.vm.hostname = hostname
      if(NETWORK_TYPE_DHCP == info[:net_type]) then
        host.vm.network :private_network, auto_config: info[:net_auto_config], :mac => "#{info[:mac_address]}", type: NETWORK_TYPE_DHCP, virtualbox__intnet: INTNET_NAME
      elsif(NETWORK_TYPE_STATIC_IP == info[:net_type])
        host.vm.network :private_network, auto_config: info[:net_auto_config], :mac => "#{info[:mac_address]}", ip: "#{info[:ip]}", :netmask => "#{info[:subnet_mask]}", virtualbox__intnet: INTNET_NAME
      end
      host.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--cpus", info[:cpus]]
        vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
        vb.customize ["modifyvm", :id, "--memory", info[:mem]]
        vb.customize ["modifyvm", :id, "--name", hostname]
        vb.customize ["modifyvm", :id, "--nicbootprio2", "1"]
        if(!hostname.include? DNSMASQ_MACHINE_NAME) then
          vb.customize ["modifyvm", :id, "--nic1", "none"]
        end
        vb.gui = info[:show_gui]
        vb.name = hostname
      end
      if(hostname.include? ANSIBLE_CONTROL_MACHINE_NAME) then
        host.vm.provision "shell", path: "scripts/install_docker.sh"
      end
    end
  end
end
