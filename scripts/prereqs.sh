#!/bin/bash

echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  🐥 Install prereqs"
echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  "

yum check-update
yum update -y
yum -y install nano tree jq openldap* openssh-server openssh-clients net-tools python-jinja2 python-paramiko sshpass wget git zile net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct openssl-devel httpd-tools python-cryptography python2-pip python-devel python-passlib java-1.8.0-openjdk-headless "@Development Tools"

yum install -y docker-1.13.1
systemctl start docker && systemctl enable docker && systemctl status docker
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

rm -f /etc/hosts
cat <<EOL | tee -a /etc/hosts
127.0.0.1 localhost.localdomain localhost
127.0.0.1 localhost4.localdomain4 localhost4
EOL
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
sed -i 's/manage_etc_hosts: True/manage_etc_hosts: False/g' /etc/cloud/cloud.cfg
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl enable NetworkManager && systemctl start NetworkManager
systemctl start firewalld --now

ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
