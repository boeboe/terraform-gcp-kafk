output "grafana_url" {
  value = format("http://%s:3000", google_compute_instance.grafana.network_interface.0.access_config.0.nat_ip)
}
