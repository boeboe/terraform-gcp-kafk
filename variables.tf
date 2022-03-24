variable "project" {
  description = "Project for the kafa/zookeeper cluster, management and monitoring plane"
  type        = string
}

variable "region" {
  description = "Region for the kafa/zookeeper cluster, management and monitoring plane"
  type        = string
}

variable "management_zone" {
  description = "Zone for the management plane"
  type        = string
}

variable "monitoring_zone" {
  description = "Zone for the monitoring plane"
  type        = string
}

variable "kafka" {
  description = "Map containing kafka broker configuration"
  type = object(
    {
      count    = number
      config   = string
      data_dir = string
      zones    = list(string)
    }
  )
}

variable "zookeeper" {
  description = "Map containing zookeeper configuration"
  type = object(
    {
      count    = number
      config   = string
      data_dir = string
      zones    = list(string)
    }
  )
}