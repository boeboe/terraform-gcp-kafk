
data "template_file" "zk_startup" {
  count    = var.servers
  template = file("${path.module}/scripts/zk-startup.sh")
  vars = {
    id = "${count.index + 1}"
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