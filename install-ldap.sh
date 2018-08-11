#!/bin/bash

# Fetch the variables
. parm.txt

# function to get the current time formatted
currentTime()
{
  date +"%Y-%m-%d %H:%M:%S";
}

sudo docker service scale devops-ldap=0
sudo docker service scale devops-ldap-pwmdb=0
sudo docker service scale devops-ldapui=0
sudo docker service scale devops-ldap-pwm=0

echo ---$(currentTime)---populate the volumes---
#to zip, use: sudo tar zcvf devops_ldap_volume.tar.gz /var/nfs/volumes/devops_ldap*
sudo tar zxvf devops_ldap_volume.tar.gz -C /


echo ---$(currentTime)---create ldap service---
sudo docker service create -d \
--name devops-ldap \
--mount type=volume,source=devops_ldap_volume_data,destination=/var/lib/ldap,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_ldap_volume_data \
--mount type=volume,source=devops_ldap_volume_slapd,destination=/etc/ldap/slapd.d,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_ldap_volume_slapd \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$LDAP_IMAGE

echo ---$(currentTime)---create ldap pwmdb service---
sudo docker service create -d \
--name devops-ldap-pwmdb \
--mount type=volume,source=devops_ldap_pwmdb_volume,destination=/var/lib/mysql,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_ldap_pwmdb_volume \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$LDAP_PWMDB_IMAGE

echo ---$(currentTime)---create ldap ui service---
sudo docker service create -d \
--publish $LDAP_PORT:80 \
--name devops-ldapui \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$LDAPUI_IMAGE

echo ---$(currentTime)---create ldap pwm service---
sudo docker service create -d \
--publish $LDAP_PWM_PORT:8443 \
--name devops-ldap-pwm \
--mount type=volume,source=devops_ldap_pwm_volume,destination=/config,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_ldap_pwm_volume \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$LDAP_PWM_IMAGE

sudo docker service scale devops-ldap-pwm=1
sudo docker service scale devops-ldapui=1
sudo docker service scale devops-ldap-pwmdb=1
sudo docker service scale devops-ldap=1

