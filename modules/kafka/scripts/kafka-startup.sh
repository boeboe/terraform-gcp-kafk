#!/bin/bash
yum -y install wget
yum -y install java-1.8.0-openjdk

useradd kafka -m
echo -e "kafka\nkafka" | passwd kafka
usermod -aG wheel kafka

wget https://downloads.apache.org/kafka/3.1.0/kafka_2.13-3.1.0.tgz
tar -xvf kafka_2.13-3.1.0.tgz
rm kafka_2.13-3.1.0.tgz
mv kafka_2.13-3.1.0 kafka
mv kafka /opt
chown -R kafka:kafka /opt/kafka

cat <<EOF | tee /opt/kafka/config/server.properties
advertised.listeners=PLAINTEXT://kafka{{broker_id}}:9092
auto.create.topics.enable=true
broker.id={{broker_id}}
default.replication.factor=3
delete.topic.enable=true
log.dirs=/data/kafka
log.retention.check.interval.ms=300000
log.retention.hours=168
log.segment.bytes=1073741824
min.insync.replicas=2
num.partitions=8
offsets.topic.replication.factor=3
zookeeper.connect=zoo1:2181,zoo2:2181,zoo3:2181/kafka
zookeeper.connection.timeout.ms=6000
EOF
chown kafka:kafka /opt/kafka/config/server.properties

cat <<EOF | tee /etc/systemd/system/kafka.service
[Unit]
Description=Kafka Daemon
Documentation=https://kafka.apache.org
Requires=network.target
After=network.target

[Service]    
Type=simple
WorkingDirectory=/opt/kafka
User=kafka
Group=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal
TimeoutSec=900

[Install]
WantedBy=multi-user.target
EOF
chown kafka:kafka /etc/systemd/system/kafka.service

wget https://dl.influxdata.com/telegraf/releases/telegraf-1.21.4-1.x86_64.rpm
yum -y localinstall telegraf-1.21.4-1.x86_64.rpm
rm telegraf-1.21.4-1.x86_64.rpm

cat <<EOF | tee /etc/telegraf/telegraf.conf
[global_tags]

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  hostname = ""
  omit_hostname = false

[[outputs.influxdb]]
  urls = ["http://influxdb:8086"]
  database = "telegraf_db"
  retention_policy = ""
  write_consistency = "any"
  timeout = "5s"
  username = "telegraf_user"
  password = "password"
EOF

cat <<EOF | tee /etc/telegraf/telegraf.d/system.conf
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  fielddrop = ["time_*"]

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.diskio]]

[[inputs.kernel]]

[[inputs.mem]]

[[inputs.processes]]

[[inputs.swap]]

[[inputs.system]]

[[inputs.net]]

[[inputs.netstat]]

[[inputs.interrupts]]

[[inputs.linux_sysctl_fs]]

EOF

cat <<EOF | tee /etc/telegraf/telegraf.d/jolokia.conf
[[inputs.jolokia2_agent]]
   urls = ["http://localhost:7777/jolokia/"]

[[inputs.jolokia2_agent.metric]]
    name  = "java_runtime"
    mbean = "java.lang:type=Runtime"
    paths = ["Uptime"]

[[inputs.jolokia2_agent.metric]]
    name  = "java_memory"
    mbean = "java.lang:type=Memory"
    paths = ["HeapMemoryUsage", "NonHeapMemoryUsage", "ObjectPendingFinalizationCount"]

[[inputs.jolokia2_agent.metric]]
    name     = "java_garbage_collector"
    mbean    = "java.lang:name=*,type=GarbageCollector"
    paths    = ["CollectionTime", "CollectionCount"]
    tag_keys = ["name"]

[[inputs.jolokia2_agent.metric]]
    name  = "java_last_garbage_collection"
    mbean = "java.lang:name=*,type=GarbageCollector"
    paths = ["LastGcInfo"]
    tag_keys = ["name"]

[[inputs.jolokia2_agent.metric]]
    name  = "java_threading"
    mbean = "java.lang:type=Threading"
    paths = ["TotalStartedThreadCount", "ThreadCount", "DaemonThreadCount", "PeakThreadCount"]

[[inputs.jolokia2_agent.metric]]
    name  = "java_class_loading"
    mbean = "java.lang:type=ClassLoading"
    paths = ["LoadedClassCount", "UnloadedClassCount", "TotalLoadedClassCount"]

[[inputs.jolokia2_agent.metric]]
    name     = "java_memory_pool"
    mbean    = "java.lang:name=*,type=MemoryPool"
    paths    = ["Usage", "PeakUsage", "CollectionUsage"]
    tag_keys = ["name"]

EOF

wget https://github.com/rhuss/jolokia/releases/download/v1.7.1/jolokia-1.7.1-bin.tar.gz
mkdir /opt/jolokia-1.7.1
chown kafka:kafka /opt/jolokia-1.7.1
tar -xvf jolokia-1.7.1-bin.tar.gz -C /opt
rm jolokia-1.7.1-bin.tar.gz

sudo sed -i '/^exec $base_dir\/kafka-run-class.sh.*/i export KAFKA_OPTS="-javaagent:\/opt\/jolokia-1.7.1\/agents\/jolokia-jvm.jar=port=7777,host=0.0.0.0"' /opt/kafka/bin/kafka-server-start.sh

cat <<EOF | tee --append /etc/security/limits.conf
* hard nofile 100000
* soft nofile 100000
EOF

echo 'type=83' | sfdisk /dev/sdb
mkfs.xfs -f /dev/sdb
mkdir -p /data/kafka
echo '/dev/sdb /data/kafka xfs user,defaults 0 0' >> /etc/fstab
mount -a
chown -R kafka:kafka /data/kafka

sed -i 's/{{broker_id}}/${broker_id}/g' /opt/kafka/config/server.properties

systemctl enable kafka
systemctl start kafka
systemctl enable telegraf
systemctl start telegraf
