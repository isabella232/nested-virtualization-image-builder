#!/bin/sh

echo "ubuntu" | sudo -S sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 quiet splash"' /etc/default/grub
sudo update-grub

sudo apt update
sudo apt-get -y install cloud-init gdisk netplan.io walinuxagent 
sudo systemctl stop walinuxagent 

sudo rm -f /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg /etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg /etc/cloud/cloud.cfg.d/99-installer.cfg /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
sudo rm -f /etc/cloud/ds-identify.cfg
sudo rm -f /etc/netplan/*.yaml
sudo rm -f /etc/cloud/cloud.cfg.d/90_dpkg.cfg

sudo sh -c "cat >> /etc/cloud/cloud.cfg.d/90_dpkg.cfg" << 'EOF'
datasource_list: [ Azure ]
EOF

sudo sh -c "cat >> /etc/cloud/cloud.cfg.d/90-azure.cfg" << 'EOF'
system_info:
   package_mirrors:
     - arches: [i386, amd64]
       failsafe:
         primary: http://archive.ubuntu.com/ubuntu
         security: http://security.ubuntu.com/ubuntu
       search:
         primary:
           - http://azure.archive.ubuntu.com/ubuntu/
         security: []
     - arches: [armhf, armel, default]
       failsafe:
         primary: http://ports.ubuntu.com/ubuntu-ports
         security: http://ports.ubuntu.com/ubuntu-ports
EOF

sudo sh -c "cat >> /etc/cloud/cloud.cfg.d/10-azure-kvp.cfg" << 'EOF'
reporting:
  logging:
    type: log
  telemetry:
    type: hyperv
EOF

sudo sed -i 's/Provisioning.Enabled=y/Provisioning.Enabled=n/g' /etc/waagent.conf
sudo sed -i 's/Provisioning.UseCloudInit=n/Provisioning.UseCloudInit=y/g' /etc/waagent.conf
sudo sed -i 's/ResourceDisk.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf
sudo sed -i 's/ResourceDisk.EnableSwap=y/ResourceDisk.EnableSwap=n/g' /etc/waagent.conf

sudo sh -c "cat >>  /etc/waagent.conf" << 'EOF'
# For Azure Linux agent version >= 2.2.45, this is the option to configure,
# enable, or disable the provisioning behavior of the Linux agent.
# Accepted values are auto (default), waagent, cloud-init, or disabled.
# A value of auto means that the agent will rely on cloud-init to handle
# provisioning if it is installed and enabled, which in this case it will.
Provisioning.Agent=auto
EOF

sudo cloud-init clean --logs --seed
sudo rm -rf /var/lib/cloud/
sudo systemctl stop walinuxagent.service
sudo rm -rf /var/lib/waagent/
sudo rm -f /var/log/waagent.log

# tmp
#sudo waagent -force -deprovision+user
#sudo rm -f ~/.bash_history
#export HISTSIZE=0
#logout