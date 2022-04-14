#!/bin/bash
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  🐥 Prepare Ansible"
echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  "

yum install -y python-jinja2 python-paramiko sshpass PyYAML pyOpenSSL

rpm -Uvh https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.9.9-1.el7.ans.noarch.rpm

git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible && git fetch && git checkout release-3.11

eth0ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
eth1ip=$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
shortname=$(hostname -s)
newhostname=$shortname.$eth1ip.nip.io

hostnamectl set-hostname $newhostname

echo "echo  ✅  create ansible hosts"

rm -rf /etc/ansible/hosts
cat << EOL | tee -a /etc/ansible/hosts
#bare minimum hostfile

[OSEv3:children]
masters
nodes
etcd

[OSEv3:vars]
# if your target hosts are Fedora uncomment this
#ansible_python_interpreter=/usr/bin/python3
openshift_deployment_type=origin
openshift_portal_net=172.30.0.0/16
# localhost likely doesn't meet the minimum requirements
openshift_disable_check=disk_availability,memory_availability,docker_storage

openshift_node_groups=[{'name': 'node-config-all-in-one', 'labels': ['node-role.kubernetes.io/master=true', 'node-role.kubernetes.io/infra=true', 'node-role.kubernetes.io/compute=true']}]

openshift_public_hostname=${newhostname}
openshift_master_default_subdomain=apps.${newhostname}
os_firewall_use_firewalld=true

[masters]
${newhostname} ansible_connection=local

[etcd]
${newhostname}  ansible_connection=local

[nodes]
${newhostname}  ansible_connection=local openshift_node_group_name='node-config-all-in-one'
EOL

echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  🐥 Install OKD v3.11 "
echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  "

cd ~/openshift-ansible
ansible-playbook playbooks/prerequisites.yml
ansible-playbook playbooks/deploy_cluster.yml
