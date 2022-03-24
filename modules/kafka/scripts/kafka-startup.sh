#!/bin/bash
yum -y install wget
yum -y install java-1.8.0-openjdk

# Add dedicated kafka user
useradd kafka -m
echo -e "kafka\nkafka" | passwd kafka
usermod -aG wheel kafka

# Install kafka package
wget https://downloads.apache.org/kafka/3.1.0/kafka_2.13-3.1.0.tgz
tar -xvf kafka_2.13-3.1.0.tgz
rm kafka_2.13-3.1.0.tgz
mv kafka_2.13-3.1.0 kafka
mv kafka /opt
chown -R kafka:kafka /opt/kafka

# Improve system performance parameters
echo 'vm.swappiness=1' | tee --append /etc/sysctl.conf
cat <<EOF | tee --append /etc/security/limits.conf
${limit_conf}
EOF

# Create kafka topic disk and directory
echo 'type=83' | sfdisk /dev/sdb
mkfs.xfs -f /dev/sdb
mkdir -p ${data_dir}
echo "/dev/sdb ${data_dir} xfs user,defaults 0 0" >> /etc/fstab
mount -a
chown -R kafka:kafka ${data_dir}

# Configure kafka
cat <<EOF | tee /opt/kafka/config/kafka.properties
${config}
EOF
sed -i 's/{{broker_id}}/${broker_id}/g' /opt/kafka/config/kafka.properties
chown kafka:kafka /opt/kafka/config/kafka.properties

# Configure kafka systemd startup service
cat <<EOF | tee /etc/systemd/system/kafka.service
${systemd_service}
EOF
chown kafka:kafka /etc/systemd/system/kafka.service

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
chown kafka:kafka /opt/jolokia-1.7.1
tar -xvf jolokia-1.7.1-bin.tar.gz -C /opt
rm jolokia-1.7.1-bin.tar.gz
cat <<EOF | tee /etc/telegraf/telegraf.d/jolokia.conf
${telegrafd_jolokia_conf}
EOF
sudo sed -i '/^exec $base_dir\/kafka-run-class.sh.*/i export KAFKA_OPTS="-javaagent:\/opt\/jolokia-1.7.1\/agents\/jolokia-jvm.jar=port=7777,host=0.0.0.0"' /opt/kafka/bin/kafka-server-start.sh

# Enable and start zookeeper systemd service
systemctl enable kafka
systemctl start kafka
systemctl enable telegraf
systemctl start telegraf
