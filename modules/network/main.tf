resource "google_compute_network" "kafka_vpc" {
  name                    = "kafka-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kafka_subnet" {
  name          = "kafka-subnet"
  ip_cidr_range = "10.1.1.0/24"
  region        = var.cluster_region
  network       = google_compute_network.kafka_vpc.self_link
}

resource "google_compute_subnetwork" "management_subnet" {
  name          = "management-subnet"
  ip_cidr_range = "10.1.2.0/24"
  region        = var.cluster_region
  network       = google_compute_network.kafka_vpc.self_link
}

resource "google_compute_subnetwork" "monitoring_subnet" {
  name          = "monitoring-subnet"
  ip_cidr_range = "10.1.3.0/24"
  region        = var.cluster_region
  network       = google_compute_network.kafka_vpc.self_link
}

resource "google_compute_firewall" "allow-internal" {
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
    google_compute_subnetwork.kafka_subnet.ip_cidr_range,
    google_compute_subnetwork.management_subnet.ip_cidr_range,
    google_compute_subnetwork.monitoring_subnet.ip_cidr_range
  ]
}
resource "google_compute_firewall" "allow-ssh" {
  name    = format("%s-allow-ssh", google_compute_network.kafka_vpc.name)
  network = google_compute_network.kafka_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow-http" {
  name    = format("%s-allow-http", google_compute_network.kafka_vpc.name)
  network = google_compute_network.kafka_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "3000"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}