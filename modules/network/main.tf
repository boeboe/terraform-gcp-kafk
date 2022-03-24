resource "google_compute_network" "kafka_vpc" {
  name                    = "kafka-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kafka_zk_subnet" {
  name          = "kafka-zk-subnet"
  ip_cidr_range = "10.1.1.0/24"
  region        = var.region
  network       = google_compute_network.kafka_vpc.self_link
}

resource "google_compute_subnetwork" "management_subnet" {
  name          = "management-subnet"
  ip_cidr_range = "10.1.2.0/24"
  region        = var.region
  network       = google_compute_network.kafka_vpc.self_link
}

resource "google_compute_subnetwork" "monitoring_subnet" {
  name          = "monitoring-subnet"
  ip_cidr_range = "10.1.3.0/24"
  region        = var.region
  network       = google_compute_network.kafka_vpc.self_link
}

resource "google_compute_firewall" "allow_internal" {
  name    = format("%s-allow-internal", google_compute_network.kafka_vpc.name)
  network = google_compute_network.kafka_vpc.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    google_compute_subnetwork.kafka_zk_subnet.ip_cidr_range,
    google_compute_subnetwork.management_subnet.ip_cidr_range,
    google_compute_subnetwork.monitoring_subnet.ip_cidr_range
  ]
}
resource "google_compute_firewall" "allow_ssh" {
  name    = format("%s-allow-ssh", google_compute_network.kafka_vpc.name)
  network = google_compute_network.kafka_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_http" {
  name    = format("%s-allow-http", google_compute_network.kafka_vpc.name)
  network = google_compute_network.kafka_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "3000"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_router" "router_kafka" {
  name    = "router-kafka"
  region  = var.region
  network = google_compute_network.kafka_vpc.id
}

resource "google_compute_router_nat" "nat_router_kafka" {
  name                               = "nat-router-kafka"
  router                             = google_compute_router.router_kafka.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
