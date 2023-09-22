#!/usr/bin/env ruby

Vagrant.require_version ">= 2.1.4"

required_plugins = %w(vagrant-reload)
required_plugins.each do |plugin|
  raise "\"#{plugin}\" plugin is not installed!" unless Vagrant.has_plugin? plugin
end

msvcs = [15, 16]

Vagrant.configure("2") do |config|
  msvcs.each do |msvc|
    vmname = "win-msvc%s" % [msvc]
    outputdir = "C:\\vagrant\\msvc#{msvc}\\snapshots"
    snapshot1dir = "#{outputdir}\\SNAPSHOT-01"
    snapshot2dir = "#{outputdir}\\SNAPSHOT-02"
    #    snapshot2windir = "C:\\vagrant\\msvc#{msvc}\\snapshots\\SNAPSHOT-02"
    cmpdir = "#{outputdir}\\CMP"

    config.vm.define vmname do |vmconfig|
      # vmconfig.vm.box = "peru/windows-10-enterprise-x64-eval"

      # config.vm.network "private_network", type: "dhcp"
      vmconfig.vm.box = "jborean93/WindowsServer2016"
      #      vmconfig.vm.guest = :windows
      #      vmconfig.vm.synced_folder "build", "/vagrant", type: "rsync", rsync__verbose: true
      vmconfig.vm.communicator = "winrm"
      vmconfig.winssh.username = "vagrant"
      vmconfig.winssh.password = "vagrant"

      vmconfig.vm.provision "shell", path: "scripts/setup.ps1"
      vmconfig.vm.provision :reload
      vmconfig.vm.provision "shell", path: "scripts/snapshot.bat", args: [snapshot1dir]

      if msvc == 15
        vmconfig.vm.provision "shell", path: "scripts/vs2017.ps1", args: [snapshot2dir] #, snapshot2windir]
        vmconfig.vm.provision :reload
        vmconfig.vm.provision "shell", path: "scripts/vs2017_postinst.ps1", args: [snapshot2dir] #, snapshot2windir]
      elsif msvc == 16
        vmconfig.vm.provision "shell", path: "scripts/vs2019.ps1", args: [snapshot2dir]
      end

      #      vmconfig.vm.provision :reload
      vmconfig.vm.provision "shell", path: "scripts/snapshot.bat", args: [snapshot2dir]
      vmconfig.vm.provision "shell", path: "scripts/compare-snapshots.bat",
                                     args: [snapshot1dir, snapshot2dir, cmpdir]
    end
  end
end
