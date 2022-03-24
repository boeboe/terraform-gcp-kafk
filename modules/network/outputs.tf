output "kafka_vpc" {
  value = google_compute_network.kafka_vpc.self_link
}

output "kafka_zk_subnet" {
  value = google_compute_subnetwork.kafka_zk_subnet.self_link
}

output "management_subnet" {
  value = google_compute_subnetwork.management_subnet.self_link
}

output "monitoring_subnet" {
  value = google_compute_subnetwork.monitoring_subnet.self_link
}