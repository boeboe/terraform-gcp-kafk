provider "google" {
  project = var.gcp_project
  region  = var.cluster_region
}

module "network" {
  source         = "./modules/network"
  cluster_region = var.cluster_region
}

module "zookeeper" {
  source  = "./modules/zookeeper"
  servers = 3
  subnet  = module.network.kafka_subnet
  zones   = var.cluster_zones
}

module "kafka" {
  source       = "./modules/kafka"
  servers      = 3
  subnet       = module.network.kafka_subnet
  zones        = var.cluster_zones
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