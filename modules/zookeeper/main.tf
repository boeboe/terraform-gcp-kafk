
data "template_file" "zk_startup" {
  count    = var.servers
  template = file("${path.module}/scripts/zk-startup.sh")
  vars = {
    config   = var.config
    data_dir = var.data_dir    
    zk_id    = "${count.index + 1}"

    limit_conf             = file("${path.module}/files/limit.conf")
    systemd_service        = file("${path.module}/files/zk.service")
    telegraf_conf          = file("${path.module}/files/telegraf/telegraf.conf")
    telegrafd_jolokia_conf = file("${path.module}/files/telegraf/jolokia.conf")
    telegrafd_system_conf  = file("${path.module}/files/telegraf/system.conf")
  }
}

resource "google_compute_instance" "zookeeper" {
  count        = var.servers
  name         = format("zoo%s", count.index + 1)
  machine_type = "n1-standard-2"
  zone         = var.zones[count.index]
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    subnetwork = var.subnet
  }

  metadata = {
    VmDnsSetting = "GlobalOnly"
  }

  metadata_startup_script = element(data.template_file.zk_startup.*.rendered, count.index)

}