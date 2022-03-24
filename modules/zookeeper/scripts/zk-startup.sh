#!/bin/bash
yum -y install wget
yum -y install java-1.8.0-openjdk

# Add dedicated zk user
useradd zk -m
echo -e "zk\nzk" | passwd zk
usermod -aG wheel zk

# Install kafka package (including zookeeper)
wget https://downloads.apache.org/kafka/3.1.0/kafka_2.13-3.1.0.tgz
tar -xvf kafka_2.13-3.1.0.tgz
rm kafka_2.13-3.1.0.tgz
mv kafka_2.13-3.1.0 kafka
mv kafka /opt
chown -R zk:zk /opt/kafka

# Improve system performance parameters
echo 'vm.swappiness=1' | tee --append /etc/sysctl.conf
cat <<EOF | tee --append /etc/security/limits.conf
${limit_conf}
EOF

# Create zookeeper data directory and set zookeeper id
mkdir ${data_dir}
chown zk:zk ${data_dir}
echo ${zk_id} > ${data_dir}/myid
chown zk:zk ${data_dir}/myid

# Configure zookeeper
cat <<EOF | tee /opt/kafka/config/zookeeper.properties
${config}
EOF
chown zk:zk /opt/kafka/config/zookeeper.properties

# Configure zookeeper systemd startup service
cat <<EOF | tee /etc/systemd/system/zk.service
${systemd_service}
EOF
chown zk:zk /etc/systemd/system/zk.service

# Install and configure telegraf
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.21.4-1.x86_64.rpm
yum -y localinstall telegraf-1.21.4-1.x86_64.rpm
rm telegraf-1.21.4-1.x86_64.rpm
cat <<EOF | tee /etc/telegraf/telegraf.conf
${telegraf_conf}
EOF
cat <<EOF | tee /etc/telegraf/telegraf.d/system.conf
${telegrafd_system_conf}
EOF

# Install and configure jolokia
wget https://github.com/rhuss/jolokia/releases/download/v1.7.1/jolokia-1.7.1-bin.tar.gz
mkdir /opt/jolokia-1.7.1
chown zk:zk /opt/jolokia-1.7.1
tar -xvf jolokia-1.7.1-bin.tar.gz -C /opt
rm jolokia-1.7.1-bin.tar.gz
cat <<EOF | tee /etc/telegraf/telegraf.d/jolokia.conf
${telegrafd_jolokia_conf}
EOF
sudo sed -i '/^exec $base_dir\/kafka-run-class.sh.*/i export KAFKA_OPTS="-javaagent:\/opt\/jolokia-1.7.1\/agents\/jolokia-jvm.jar=port=7777,host=0.0.0.0"' /opt/kafka/bin/zookeeper-server-start.sh

# Enable and start zookeeper systemd service
systemctl enable zk
systemctl start zk
systemctl enable telegraf
systemctl start telegraf
