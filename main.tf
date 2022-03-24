provider "google" {
  project = var.project
  region  = var.region
}

module "network" {
  source = "./modules/network"

  region = var.region
}

module "zookeeper" {
  source = "./modules/zookeeper"

  config   = var.zookeeper.config
  data_dir = var.zookeeper.data_dir
  servers  = var.zookeeper.count
  subnet   = module.network.kafka_zk_subnet
  zones    = var.zookeeper.zones
}

module "kafka" {
  source       = "./modules/kafka"

  config       = var.kafka.config
  data_dir     = var.kafka.data_dir
  servers      = var.kafka.count
  subnet       = module.network.kafka_zk_subnet
  zones        = var.kafka.zones
  zookeeper_up = module.zookeeper.cluster_up
}

module "management" {
  source = "./modules/management"

  subnet = module.network.management_subnet
  zone   = var.management_zone
}

module "monitoring" {
  source = "./modules/monitoring"

  subnet = module.network.monitoring_subnet
  zone   = var.monitoring_zone
}