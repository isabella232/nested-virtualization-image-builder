#!/bin/sh

sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 quiet splash"' /etc/default/grub
update-grub

apt update
apt-get -y install cloud-init gdisk netplan.io walinuxagent 

rm -f /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg /etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg /etc/cloud/cloud.cfg.d/99-installer.cfg /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/ds-identify.cfg
rm -f /etc/netplan/*.yaml
rm -f /etc/cloud/cloud.cfg.d/90_dpkg.cfg

sh -c "cat >> /etc/cloud/cloud.cfg.d/90_dpkg.cfg" << 'EOF'
datasource_list: [ Azure ]
EOF

sh -c "cat >> /etc/cloud/cloud.cfg.d/90-azure.cfg" << 'EOF'
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

sh -c "cat >> /etc/cloud/cloud.cfg.d/10-azure-kvp.cfg" << 'EOF'
reporting:
  logging:
    type: log
  telemetry:
    type: hyperv
EOF

sed -i 's/Provisioning.Enabled=y/Provisioning.Enabled=n/g' /etc/waagent.conf
sed -i 's/Provisioning.UseCloudInit=n/Provisioning.UseCloudInit=y/g' /etc/waagent.conf
sed -i 's/ResourceDisk.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf
sed -i 's/ResourceDisk.EnableSwap=y/ResourceDisk.EnableSwap=n/g' /etc/waagent.conf

sh -c "cat >>  /etc/waagent.conf" << 'EOF'
# For Azure Linux agent version >= 2.2.45, this is the option to configure,
# enable, or disable the provisioning behavior of the Linux agent.
# Accepted values are auto (default), waagent, cloud-init, or disabled.
# A value of auto means that the agent will rely on cloud-init to handle
# provisioning if it is installed and enabled, which in this case it will.
Provisioning.Agent=auto
EOF

cloud-init clean --logs --seed
rm -rf /var/lib/cloud/
systemctl stop walinuxagent.service
rm -rf /var/lib/waagent/
rm -f /var/log/waagent.log

waagent -force -deprovision+user
rm -f ~/.bash_history
export HISTSIZE=0