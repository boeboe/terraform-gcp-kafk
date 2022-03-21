output "zoo_navigator_url" {
  value = format("http://%s", google_compute_instance.zoo_navigator.network_interface.0.access_config.0.nat_ip)
}

output "kafka_drop_url" {
  value = format("http://%s", google_compute_instance.kafka_drop.network_interface.0.access_config.0.nat_ip)
}
