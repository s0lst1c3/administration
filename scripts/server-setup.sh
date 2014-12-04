#!/bin/bash
# scriptname: server-setup.sh
# author: solstice
# description: automates basic configuration of a remote server.
# usage:
#     ssh root@SERVER 'bash -s' < server-setup.sh
################################################################

# CONFIGS
user=''
install_us=''

# INITIAL USER SETUP
# change the root password
passwd

# create admin user
adduser $user
passwd $user

visudo

# INSTALL BASIC UTILS
# figure out which package manager to use
install_cmd=''
if [ -n $(which yum) ]; then
	install_cmd='yum install'
elif [ -n $(which apt-get) ]; then
	install_cmd='apt-get install'
else
	echo "Can't find package manager. Exiting"
	exit
fi

# install basic goodies plus additional stuff we might needed
`$install_cmd` vim tmux python2 $install_us

#read -a items <<< "$2"
#for item in "${items[@]}"
#do
#	yum install $item
#done

# CONFIGURE SSH
# check to see if sshconfig is in an obvious location.
# if not, find it.
ssh_config=''
if [  -d /etc/ssh ] && [ -f /etc/ssh/sshconfig ]; then
	ssh_config='/etc/ssh/sshconfig'
else
	ssh_config=$(find /etc -name sshconfig)
fi

# make a backup of the sshconfig file
cp $ssh_config "$ssh_config.backup"

# nuke existing configs from sshconfig
set_port1='/^#Port / d'
set_port2='/^Port / d'
set_protocol1='/^#Protocol / d'
set_protocol2='/^Protocol / d'
set_rlogin1='/^#PermitRootLogin / d'
set_rlogin2='/^PermitRootLogin / d'
sed -e $set_port1 -e $set_port2 -e $set_protocol1 -e $set_protocol2 -e $set_rlogin1 -e $set_rlogin2 < $ssh_config > newssh

# replace with safer ones
echo "Port 24444" >> newssh
echo "Protocol 2" >> newssh
echo "PermitRootLogin no" >> newssh
echo "AllowUsers $user"
mv newssh $ssh_config

# reload configs
service sshd reload

# ADD BRUTEFORCE PROTECTION
# install fail2ban
`$installer` fail2ban

# locate fail2ban config file
fail2ban_conf=''
if [  -d /etc/fail2ban ] && [ -f /etc/fail2ban/jail.conf ]; then
	fail2ban_conf='/etc/fail2ban/jail.conf'
else
	fail2ban_conf=$(find /etc -name jail.conf)
fi

# create a local copy of the fail2ban config
cp $fail2ban_conf '/etc/fail2ban/jail.local'

# restart fail2ban server
`'service fail2ban restart'`

# list current iptables rules
iptables -L
