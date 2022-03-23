resource "google_compute_instance" "zoo_navigator" {
  name         = "zoo-navigator"
  machine_type = "g1-small"
  zone         = var.zone
  tags         = ["ssh", "http-server"]

  boot_disk {
    initialize_params {
      image = "gce-uefi-images/cos-stable"
    }
  }

  network_interface {
    subnetwork = var.subnet
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "docker run -d -p 80:9000 -e HTTP_PORT=9000 --name zoo-navigator --restart unless-stopped elkozmon/zoonavigator:latest"

}

# resource "google_compute_instance" "zk_web" {
#   name         = "zk-web"
#   machine_type = "g1-small"
#   zone         = var.zone
#   tags         = ["ssh", "http-server"]

#   boot_disk {
#     initialize_params {
#       image = "gce-uefi-images/cos-stable"
#     }
#   }

#   network_interface {
#     subnetwork = var.subnet
#     access_config {
#       // Ephemeral IP
#     }
#   }

#   metadata_startup_script = "docker run -d -p 80:8080 -e ZKWEB_PORT=8080 -e ZKWEB_CREDENTIALS=admin:admin -e ZKWEB_DEFAULT_NODE=zoo1:2181 --name zk-web --restart unless-stopped noteax/zk-web-docker:latest"

# }

resource "google_compute_instance" "kafka_drop" {
  name         = "kafka-drop"
  machine_type = "g1-small"
  zone         = var.zone
  tags         = ["ssh", "http-server"]

  boot_disk {
    initialize_params {
      image = "gce-uefi-images/cos-stable"
    }
  }

  network_interface {
    subnetwork = var.subnet
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "docker run -d -p 80:9000 -e KAFKA_BROKERCONNECT='kafka1:9092,kafka2:9092,kafka3:9092' -e JVM_OPTS='-Xms32M -Xmx64M' -e SERVER_SERVLET_CONTEXTPATH='/' --name kafka-drop --restart unless-stopped obsidiandynamics/kafdrop:latest"

}
