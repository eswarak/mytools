#!/bin/bash
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  🐥 Installing OpenLDAP"
echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  "

eth0ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
eth1ip=$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
shortname=$(hostname -s)
newhostname=$shortname.$eth1ip.nip.io

cd ~/
echo "Updating ldap files ..."

wget https://raw.githubusercontent.com/eswarak/mytools/main/openldap/install-ldap.yaml
sed -i "s/dc=MYBASE/dc=ibm.dc=com/g" ./install-ldap.yaml
sed -i "s/MYDOMAIN/ibm.com/g" ./install-ldap.yaml
sed -i "s/MYLDAPPASSWORD/1bmT3chAc@demy/g" ./install-ldap.yaml
sed -i "s/MYLDAPPASSWORDADMIN/1bmT3chAc@demyAdm1n/g" ./install-ldap.yaml

echo "deploy to the okd cluster..."
oc login -u system:admin
oc new-project openldap

oc adm policy add-scc-to-user anyuid -z default
oc create -f install-ldap.yaml
sleep 60

echo "adding ldap to the cluster authentication ..."
cp /etc/origin/master/master-config.yaml /etc/origin/master/master-config.yaml.orig

echo "Creating a temp file to add .."
cat <<EOL | tee -a /tmp/ldapsnip.txt
  - name: tech-academy
    challenge: true
    login: true
    mappingMethod: claim
    provider:
      apiVersion: v1
      kind: LDAPPasswordIdentityProvider
      basedn: dc=ibm,dc=com
      attributes:
        email:
        - mail
        id:
        - uid
        preferredUsername:
        - uid
      bindDN: cn=admin,dc=ibm,dc=com
      bindPassword: 1bmT3chAc@demyAdm1n
      insecure: true
      url: "ldap://openldap.openldap.svc.cluster.local:389/ou=People,dc=ibm,dc=com?uid"
EOL

sed -i '/kind: AllowAllPasswordIdentityProvider/r /tmp/ldapsnip.txt' /etc/origin/master/master-config.yaml

echo "Restarting api and controller changes..."
master-restart api
master-restart controllers

sleep 30

oc adm policy add-cluster-role-to-user cluster-admin qotdadmin


echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  🐥 Configuring NFS.."
echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  "
yum -y install nfs-utils
systemctl start nfs-server --now
systemctl start rpcbind --now
mkdir -p /var/nfs/general
chmod -R 755 /var/nfs/general
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --reload
echo "/var/ngs/general *(rw,sync,no_root_squash)" > /etc/exports
systemctl restart nfs-server
mkdir ~/nfs
cd ~/nfs
wget https://github.com/eswarak/mytools/raw/main/nfs/nfsfiles.tar
tar xvf nfsfiles.tar
sed -i "s/MYIP/${eth1ip}/g" deployment.yaml
oc new-project nfs-fs
oc create -f rbac.yaml
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:nfs-fs:nfs-client-provisioner
oc create -f class.yaml
oc create -f deployment.yaml

