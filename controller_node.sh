#!/usr/bin/env bash

# controller_node.sh

# description: 
# it's took Hugh time to setup controller node manually 
# so this script will save your time 
# this script is tested and working on Ubuntu 12.04


# Load all required variables and functions from setup.conf and functions.sh
. ./setup.conf
. ./functions.sh

# Add Grizzly repositories [Only for Ubuntu 12.04]:
if grep 'Ubuntu 12.04 LTS' /etc/issue >/dev/null ; then 
	apt_install ubuntu-cloud-keyring
	[[ $? -ne 0 ]] && apt-get update && ./$0
	if ! grep "precise-updates/grizzly" /etc/apt/sources.list.d/grizzly.list >/dev/null 2>&1; then 
		echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" \
		  >> /etc/apt/sources.list.d/grizzly.list
	fi
fi

#updateOS

# Mysql Installation
# Reference Link http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
echo mysql-server-5.5 mysql-server/root_password password "${Mysql_Password}" | debconf-set-selections
echo mysql-server-5.5 mysql-server/root_password_again password "${Mysql_Password}" | debconf-set-selections
apt_install mysql-server  python-mysqldb 
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart

mysql -u root -p"${Mysql_Password}" <<EOF
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO "${KEYSTONEUSER}"@'%' IDENTIFIED BY "${KEYSTONEPASS}";
CREATE DATABASE glance;
GRANT ALL ON glance.* TO "${GLANCEUSER}"@'%' IDENTIFIED BY "${GLANCEPASS}";
CREATE DATABASE quantum;
GRANT ALL ON quantum.* TO "${QUANTUMUSER}"@'%' IDENTIFIED BY "${QUANTUMPASS}";
CREATE DATABASE nova;
GRANT ALL ON nova.* TO "${NOVAUSER}"@'%' IDENTIFIED BY "${NOVAPASS}";
CREATE DATABASE cinder;
GRANT ALL ON cinder.* TO "${CINDERUSER}"@'%' IDENTIFIED BY "${CINDERPASS}";
FLUSH PRIVILEGES;
EOF


# Install reuqired packages for controller 
apt_install nova-api nova-cert novnc nova-consoleauth \
			nova-scheduler nova-novncproxy nova-doc 	\
			rabbitmq-server ntp vlan bridge-utils keystone \
			cinder-api cinder-scheduler cinder-volume iscsitarget \
			open-iscsi iscsitarget-dkms	glance quantum-server nova-conductor \
			openstack-dashboard memcached

# If you don't like the OpenStack ubuntu theme, you can remove the package to disable it:
dpkg --purge openstack-dashboard-ubuntu-theme

. ./functions.sh
EnableForwarding

# Configure Keystone
CommentAppend 	"connection = sqlite:////var/lib/keystone/keystone.db" \
				"connection = mysql://${KEYSTONEUSER}:${KEYSTONEPASS}@${Controller_node_IP}/keystone" \
				/etc/keystone/keystone.conf

# Restart the identity service then synchronize the database:
service keystone restart
keystone-manage db_sync

# Reference links
# Fill up the keystone database
# https://github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/tree/OVS_MultiNode/KeystoneScripts
. ./setup.conf
./keystone_basic.sh
./keystone_endpoints_basic.sh

CreateOpenrc 
source ~/.bashrc

# Test Keystone 
echo "Testing KeyStone"
keystone user-list && echo "Keystone working.." 

# Configure Glance
AppendIfnotExists "auth_host = ${Controller_node_IP}
auth_port = 35357
auth_protocol = http
admin_tenant_name = ${SERVICE_TENANT_NAME}
admin_user = glance
admin_password = ${SERVICE_PASSWORD}" /etc/glance/glance-api-paste.ini

AppendIfnotExists "auth_host = ${Controller_node_IP}
auth_port = 35357
auth_protocol = http
admin_tenant_name = ${SERVICE_TENANT_NAME}
admin_user = glance
admin_password = ${SERVICE_PASSWORD}" /etc/glance/glance-registry-paste.ini

CommentAppend 	"sql_connection = sqlite:////var/lib/glance/glance.sqlite" \
				"sql_connection = mysql://${GLANCEUSER}:${GLANCEPASS}@${Controller_node_IP}/glance" \
				/etc/glance/glance-api.conf

AppendIfnotExists "flavor = keystone" /etc/glance/glance-api.conf

CommentAppend 	"sql_connection = sqlite:////var/lib/glance/glance.sqlite" \
				"sql_connection = mysql://${GLANCEUSER}:${GLANCEPASS}@${Controller_node_IP}/glance" \
				/etc/glance/glance-registry.conf

AppendIfnotExists "flavor = keystone" /etc/glance/glance-registry.conf

service glance-api restart; service glance-registry restart

# Synchronize the glance database
glance-manage db_sync

# Download OS
if [[ ! -f  cirros.img ]]; then
	wget -cnd https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-i386-disk.img -o cirros.img
fi

# To test Glance, upload the cirros cloud image 
glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 < cirros.img

glance image-list

