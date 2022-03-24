project = "bart-tid-kafka-playground"
region  = "europe-west1"

management_zone = "europe-west1-b"
monitoring_zone = "europe-west1-b"

kafka = {
  count = 3
  config = <<-EOT
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
  EOT
  data_dir = "/data/kafka"
  zones = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]

}

zookeeper = {
  count = 3
  config = <<-EOT
    tickTime=2000
    dataDir=/var/lib/zookeeper/
    4lw.commands.whitelist=*
    clientPort=2181
    initLimit=5
    syncLimit=2
    server.1=zoo1:2888:3888
    server.2=zoo2:2888:3888
    server.3=zoo3:2888:3888
  EOT
  data_dir = "/var/lib/zookeeper/"
  zones = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
}