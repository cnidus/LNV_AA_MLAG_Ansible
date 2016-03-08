# Example DC deployment

This is collaboration between Cumulus and CUSTOMER to automate bringing up 
a new Datacenter network.

The goal is to deploy a 2 spine 4 leaf network utilizing ONIE to install system 
images on the network switches, ZTP to setup a baseline config (deploy ssh keys),
and finally Puppet to push the actual network configurations (PTM, IP, BGP, etc). 
Since this is a 3-Day Jumpstart Engagement only limited automation tool prototyping
will be available.

There are 2 parts to the project.  First stand up the network in a virtual
environment using Cumulus VX and Vagrant.  Then deploy automation tools to configure
the virtual network.  

Once the physical equipment arrives test the same automation
on the real network.  The goal is to have a virtual development,
testing network and a production physical network.

#Files:
- etc/dhcp/dhcpd.conf: Sample dhcp file used in the Vagrant instance
- var/www/ztp_deploy.sh: Zero touch provisioning script.  Copies license
file, and authorized public key for Ansible.
- Vagrant/Vagrantfile: Vagrant definition to stand up virtual network


#Physical Component
- The network consists of 6 x Penguin Arctica 4804iq (leaf) and 2 x Penguin Arctica 4806xp (spine) . 
- Servers are connected dual attached to each leaf switch
- Leafs are connected with 1 x 10GE DAC to each spine. 
- Spines have 1x 10GE (reved down to 1G)  connection to WAN for internet/transit traffic.

#Diagrams:
![Diagram](diagram.png)
Shared Google Drawing
https://docs.google.com/a/cumulusnetworks.com/drawings/d/1xuyQdjwB6h9SmiRG7qsLECgIt17Hl9AVDRV-BZxf-yw/edit?usp=sharing

#Start up the management VM
- NOTE: Make sure to install the dependencies specified in the first ~10 lines of the Vagrantfile
- export VAGRANT_DEFAULT_PROVIDER=virtualbox; vagrant up mgmt


#Install instructions
Connect to the management VM (ssh localhost:2222) This could be a different port forward depending on your deployment.
- vagrant ssh mgmt
- login: vagrant/vagrant
- On the Management sudo to root as pretty much every command from here on out needs root priv

vagrant@mgmt:~$ sudo -i

root@mgmt:~# 
- sudo apt-get update
- sudo apt-get install -y isc-dhcp-server dnsmasq apache2
- sudo apt-get install -y python-pip shedskin libyaml-dev sshpass git
- sudo apt-get install apt-cacher
- sudo pip install ansible
- sudo pip install ansible --upgrade
- edit /etc/apt-cacher/apt-cacher.conf to uncomment allowed_hosts = 192.168.252.0/24
- sudo service apt-cacher restart

#Clone this repository into the MGMT node

root@mgmt:~# 
- git init
- git config --global user.name "Your Name"
- git config --global user.email your_email@domain.com
- git clone https://github.com/CumulusNetworks/CUSTOMER.git

#Validate OOB connection on the management station
(Make sure the IP is attached to eth0)
root@mgmt:~# 

- ifup eth0
- ip addr show eth0

#Setup DNS
- cat ~/CUSTOMER/etc/hosts | sudo tee /etc/hosts
- service dnsmasq restart

#Setup DHCP
- cp ~/CUSTOMER/etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf
- service isc-dhcp-server restart

#Copy Quagga debs to the web directory
- cp ~/CUSTOMER/var/www/*.deb /var/www/html/

#Turn up the rest of the virtual topology via Vagrant:
export VAGRANT_DEFAULT_PROVIDER=virtualbox; vagrant up

#Validate connectivity
Change into the CUSTOMER directory to run the Ansible playbooks

root@mgmt:~# cd CUSTOMER
- root@mgmt:~/CUSTOMER# 
- ansible network -m ping -u cumulus -k
  - (pwd: CumulusLinux!)
- ansible servers -m ping -u vagrant -k
  - (pwd: vagrant)

#Setup SSH keys and deploy to the network
- ssh-keygen -t rsa
- cp /root/.ssh/id_rsa.pub /var/www/html/authorized_keys
- cp ~/CUSTOMER/var/www/ztp_deploy.sh /var/www/html/
- ansible-playbook deploy_ssh_keys_network.yml -u vagrant -k
  - (pwd: vagrant)
- ansible-playbook deploy_ssh_keys_hosts.yml -u vagrant -k
  - (pwd: vagrant)

#Test passwordless connectivity to all (except for oob)
- ansible -m ping all

#Run the full playbooks
Make sure to use the --extra-vars statement to run on Vitualbox otherwise it will attempt to run ZTP as it would in production on real equipment.  
- ansible-playbook CUSTOMER.yml --extra-vars "phys_env=virt"

#Test Internet connectivity from server1
- vagrant ssh server1
- ping 8.8.8.8
