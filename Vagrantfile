# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'config/config'

required_plugins = {
  'vagrant-reload' => '0.0.1'
}

needs_restart = false
required_plugins.each do |name, version|
  unless Vagrant.has_plugin? name, version
    system "vagrant plugin install #{name} --plugin-version=\"#{version}\""
    needs_restart = true
  end
end

if needs_restart
  exec "vagrant #{ARGV.join' '}"
end

if USERNAME.nil? || USERNAME.empty?
  raise Vagrant::Errors::VagrantError.new, "You must set the $env:OS_USERNAME environment variable"
end
if PASSWORD.nil? || PASSWORD.empty?
  raise Vagrant::Errors::VagrantError.new, "You must set the $env:OS_PASSWORD environment variable"
end
if MOS_PASSWORD.nil? || MOS_PASSWORD.empty?
  raise Vagrant::Errors::VagrantError.new, "You must set the $env:MOS_PASSWORD environment variable"
end

VAGRANTFILE_API_VERSION = "2"

# Enable the typed_triggers feature so we can use Action Triggers
ENV["VAGRANT_EXPERIMENTAL"] = "typed_triggers"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define 'ps-vagabond' do |vmconfig|

    # Increase the timeout limit for booting the VM
    vmconfig.vm.boot_timeout = 600

    # Increase the timeout limit for halting the VM
    vmconfig.vm.graceful_halt_timeout = 600

    # Only download new boxes when the Vagabond picks a new release
    vmconfig.vm.box_check_update = false

    ##############
    #  Provider  #
    ##############

    # HyperV
    vmconfig.vm.provider "hyperv" do |hyperv|
      hyperv.vmname = "#{DPK_VERSION}"
      hyperv.maxmemory = "#{MEMORY}"
      hyperv.cpus = 2
      hyperv.vm_integration_services = {
        guest_service_interface: true,
        heartbeat: true,
        key_value_pair_exchange: true,
        shutdown: true,
        time_synchronization: true,
        vss: true
      }
    end

    ######################
    #  Operating System  #
    ######################

    case OPERATING_SYSTEM.upcase
    when "LINUX"
      vmconfig.vm.box = "generic/oracle7"
      vmconfig.vm.box_check_update = true
	  
      # Sync folder to be used for downloading the dpks and the base /vagrant folder
      vmconfig.vm.synced_folder "#{VAGRANT_HOME}", "/vagrant", owner: 'vagrant', group: 'vagrant', mount_options: ["domain=#{DOMAIN}","username=#{USERNAME}","password=#{PASSWORD}","vers=2.1","sec=ntlmssp","mfsymlinks","dir_mode=0777","file_mode=0775"], type: "smb", smb_password: "#{PASSWORD}", smb_username: "#{USERNAME}"
      vmconfig.vm.synced_folder "#{DPK_LOCAL_DIR}", "#{DPK_REMOTE_DIR_LNX}", owner: 'vagrant', group: 'vagrant', mount_options: ["domain=#{DOMAIN}","username=#{USERNAME}","password=#{PASSWORD}","vers=2.1","sec=ntlmssp","mfsymlinks","dir_mode=0777","file_mode=0775"], type: "smb", smb_password: "#{PASSWORD}", smb_username: "#{USERNAME}"
    else
      raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
    end

    ###########
    # Storage #
    ###########

    case OPERATING_SYSTEM.upcase
    when "LINUX"

      # Add a second drive for /opt/oracle
      vmconfig.trigger.before :"VagrantPlugins::HyperV::Action::StartInstance", type: :action do |trigger|
        trigger.info = "Add storage drive for /opt/oracle"
        trigger.run = { inline: "./scripts/hyperv-add-storage.ps1 -VmName #{DPK_VERSION} -StoragePath #{VAGRANT_HOME}"}
      end

      # extend volume group to for PeopleSoft
      $extend = <<-SCRIPT
echo 'Extending Volume Group'
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb > /dev/null 2>&1
pvcreate /dev/sdb1 > /dev/null 2>&1
vgextend ol_oracle8 /dev/sdb1 > /dev/null 2>&1
lvcreate --name ps -l +100%FREE ol_oracle8 > /dev/null 2>&1
mkfs.xfs /dev/ol_oracle8/ps > /dev/null 2>&1
mkdir -p /opt/oracle > /dev/null 2>&1
mount /dev/ol_oracle8/ps /opt/oracle > /dev/null 2>&1
echo "/dev/ol_oracle8/ps     /opt/oracle                   xfs     defaults        0 0" | tee -a /etc/fstab > /dev/null 2>&1
echo "PeopleSoft Mount: $(df -hT | grep /opt/oracle)"
SCRIPT

      vmconfig.vm.provision "storage", type: "shell", run: "once", inline: $extend

      vmconfig.trigger.after :destroy, type: :action do |trigger|
        trigger.info = "Remove storage drive"
        trigger.run = { inline: "./scripts/hyperv-remove-storage.ps1 -VmName #{DPK_VERSION} -StoragePath #{VAGRANT_HOME}"}
      end
    end

    #############
    #  Network  #
    #############

    vmconfig.vm.hostname = "#{FQDN}".downcase

    if "#{NETWORK_SETTINGS[:mac]}".nil? || "#{NETWORK_SETTINGS[:mac]}".empty?
      p "Using Dynamic MAC"
    else
      vmconfig.trigger.before :"VagrantPlugins::HyperV::Action::StartInstance", type: :action do |trigger|
        trigger.info = "Set MAC for primary adapter"
        trigger.run = { inline: "./scripts/hyperv-set-mac.ps1 -VmName #{DPK_VERSION} -MAC #{NETWORK_SETTINGS[:mac]}"}
      end
    end

    case OPERATING_SYSTEM.upcase
    when "LINUX"
        vmconfig.vm.network "public_network", ip: "#{NETWORK_SETTINGS[:ip_address]}"
        vmconfig.vm.provision "networking_setup", type: "shell", run: "once" do |script|
          script.path = "scripts/networking.sh"
          script.upload_path = "/tmp/networking.sh"
          script.env = {
            "IP_ADDRESS"       => "#{NETWORK_SETTINGS[:ip_address]}",
            "DOMAIN"           => "#{NETWORK_SETTINGS[:domain]}",
            "GATEWAY"          => "#{NETWORK_SETTINGS[:gateway]}",
            "NETWORK_SETTINGS" => "#{NETWORK_SETTINGS[:type]}"
          }
        end
    else
      raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
    end

    ##################
    #  Provisioning  #
    ##################

    case OPERATING_SYSTEM.upcase 
    when "LINUX"

      

      vmconfig.vm.provision "bootstrap-lnx", type: "shell" do |script|
        script.path = "scripts/provision.sh"
        script.upload_path = "/tmp/provision.sh"
        script.env = {
          "MOS_USERNAME" => "#{MOS_USERNAME}",
          "MOS_PASSWORD" => "#{MOS_PASSWORD}",
          "PATCH_ID"     => "#{PATCH_ID}",
          "DPK_INSTALL"  => "#{DPK_REMOTE_DIR_LNX}/#{PATCH_ID}",
          "PSFT_CFG_DIR" => "#{PSFT_CFG_DIR}"
        }
      end

      vmconfig.vm.provision "cache-lnx", type: "shell" do |script|
        script.path = "scripts/preloadcache.sh"
        script.upload_path = "/tmp/preloadcache.sh"
      end
    else
      raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
    end

    ##################
    #  Notification  #
    ##################
    # Vagrant-Pushover Notification
    # https://github.com/tcnksm/vagrant-pushover
    # install: vagrant plugin install vagrant-pushover
    # initialize: vagrant pushover-init
    # configure: $EDITOR .vagrant/pushover.rb
    if Vagrant.has_plugin?("vagrant-pushover")
      vmconfig.pushover.read_key
    end

  end

end
