#!/bin/bash

function error() {
  echo -e "\e[0;33mERROR: The Zero Touch Provisioning script failed while running the command $BASH_COMMAND at line $BASH_LINENO.\e[0m" >&2
}
trap error ERR

SSH_URL="http://192.168.252.254/authorized_keys"
LIC_URL="http://192.168.252.254/license.txt"

#Install license
wget -q -O /root/license.txt $LIC_URL
/usr/cumulus/bin/cl-license -i /root/license.txt

#Setup SSH key authentication for Ansible
mkdir -p /root/.ssh
wget -O /root/.ssh/authorized_keys $SSH_URL
mkdir -p /home/cumulus/.ssh
wget -O /home/cumulus/.ssh/authorized_keys $SSH_URL
chown -R cumulus:cumulus /home/cumulus/.ssh

## Debating if this should be done with Ansible or ZTP
#echo "Enable Managment MRF"
#apt-get -yq install cl-mgmtmrf
#/usr/sbin/cl-mgmtmrf setup eth0

#Reboot the switch
/sbin/shutdown -r -t 10 now "Rebooting switch to finish ZTP install"

exit 0
#CUMULUS-AUTOPROVISIONING

