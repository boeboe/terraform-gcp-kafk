#!/bin/bash
yum -y install wget
yum -y install java-1.8.0-openjdk

useradd zk -m
echo -e "zk\nzk" | passwd zk
usermod -aG wheel zk

wget https://downloads.apache.org/kafka/3.1.0/kafka_2.13-3.1.0.tgz
tar -xvf kafka_2.13-3.1.0.tgz
rm kafka_2.13-3.1.0.tgz
mv kafka_2.13-3.1.0 kafka
mv kafka /opt
chown -R zk:zk /opt/kafka

mkdir /var/lib/zookeeper
chown zk:zk /var/lib/zookeeper

cat <<EOF | tee /opt/kafka/config/zookeeper.properties
tickTime=2000
dataDir=/var/lib/zookeeper/
4lw.commands.whitelist=*
clientPort=2181
initLimit=5
syncLimit=2
server.1=zoo1:2888:3888
server.2=zoo2:2888:3888
server.3=zoo3:2888:3888
EOF
chown zk:zk /opt/kafka/config/zookeeper.properties

cat <<EOF | tee /etc/systemd/system/zk.service
[Unit]
Description=Zookeeper Daemon
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]    
Type=simple
WorkingDirectory=/opt/kafka
User=zk
Group=zk
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal
TimeoutSec=900

[Install]
WantedBy=multi-user.target
EOF
chown zk:zk /etc/systemd/system/zk.service

echo 'vm.swappiness=1' | tee --append /etc/sysctl.conf

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
chown zk:zk /opt/jolokia-1.7.1
tar -xvf jolokia-1.7.1-bin.tar.gz -C /opt
rm jolokia-1.7.1-bin.tar.gz

sudo sed -i '/^exec $base_dir\/kafka-run-class.sh.*/i export KAFKA_OPTS="-javaagent:\/opt\/jolokia-1.7.1\/agents\/jolokia-jvm.jar=port=7777,host=0.0.0.0"' /opt/kafka/bin/zookeeper-server-start.sh

echo ${id} > /var/lib/zookeeper/myid
chown zk:zk /var/lib/zookeeper/myid

systemctl enable zk
systemctl start zk
systemctl enable telegraf
systemctl start telegraf
