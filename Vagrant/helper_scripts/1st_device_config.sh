#!/bin/bash

#This file is transferred to a Debian/Ubuntu Host and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "  Running 1st_device_config.sh"
echo "#################################"

sudo su

#Replace existing network interfaces file
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces
echo -e  "source /etc/network/interfaces.d/*.cfg\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto vagrant" >> /etc/network/interfaces.d/vagrant.cfg
echo -e "iface vagrant inet dhcp\n\n" >> /etc/network/interfaces.d/vagrant.cfg

####### Custom Stuff

#Configure ip address on eth0
echo -e "\nauto eth0\niface eth0 inet static\n    address 192.168.252.254/24\n\n" >> /etc/network/interfaces.d/eth0.cfg

#Installations
apt-get update -y
apt-get install -y isc-dhcp-server dnsmasq apache2 python-pip shedskin libyaml-dev sshpass git apt-cacher-ng
echo "Installing Ansible..."
pip install ansible > /dev/null
pip install ansible --upgrade > /dev/null

echo "Generating SSH Key..."
/usr/bin/ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
echo "Copying Key into /var/www/html..."
cp /root/.ssh/id_rsa.pub /var/www/html/authorized_keys

REPOSITORY=""
dir=customer_name

#rest of turnup
echo "git clone $REPOSITORY" > /home/vagrant/turnup.sh
echo "cat /home/vagrant/$dir/etc/hosts | tee /etc/hosts" >> /home/vagrant/turnup.sh
echo "cp /home/vagrant/$dir/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf" >> /home/vagrant/turnup.sh
echo "/etc/init.d/isc-dhcp-server restart" >> /home/vagrant/turnup.sh
echo "cp /home/vagrant/$dir/var/www/*.deb /var/www/html/" >> /home/vagrant/turnup.sh
chmod 755 /home/vagrant/turnup.sh

echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "#################################"
echo "   Finished"
echo "#################################"
#reboot &



