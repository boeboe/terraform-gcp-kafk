variable "gcp_project" {
  description = "Project for the kafa/zookeeper cluster, management and monitoring plane"
  type        = string
}

variable "cluster_region" {
  description = "Region for the kafa/zookeeper cluster, management and monitoring plane"
  type        = string
}

variable "cluster_zones" {
  description = "Zones for the kafka/zookeeper cluster"
  type        = list(any)
}

variable "management_zone" {
  description = "Zone for the management plane"
  type        = string
}

variable "monitoring_zone" {
  description = "Zone for the monitoring plane"
  type        = string
}
