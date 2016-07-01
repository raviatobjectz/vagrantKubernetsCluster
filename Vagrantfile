# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "ravi/docker"
    master.vm.network "private_network", ip: "192.168.50.4"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end
    master.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/master.sh
      /vagrant/master.sh
    SHELL
  end
  config.vm.define "worker1" do |worker1|
    worker1.vm.box = "ravi/docker"
    worker1.vm.network "private_network", ip: "192.168.50.5"
    worker1.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end
    worker1.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/worker.sh
      /vagrant/worker.sh
    SHELL
  end
  config.vm.define "worker2" do |worker2|
    worker2.vm.box = "ravi/docker"
    worker2.vm.network "private_network", ip: "192.168.50.6"
    worker2.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end
    worker2.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/worker.sh
      /vagrant/worker.sh
    SHELL
  end
end
