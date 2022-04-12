#!/bin/bash
set -euo pipefail

# Clean cloud-init and Azure Linux agent runtime artifacts and logs
cloud-init clean --logs --seed
rm -rf /var/lib/cloud/
systemctl stop walinuxagent.service
rm -rf /var/lib/waagent/
rm -f /var/log/waagent.log

# Deprovision the virtual machine and prepare it for provisioning on Azure
waagent -force -deprovision+user
rm -f ~/.bash_history
export HISTSIZE=0
