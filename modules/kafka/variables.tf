variable "servers" {
  type = number
}

variable "subnet" {
  type = string
}

variable "zones" {
  type = list(any)
}

variable "zookeeper_up" {
  type = bool
}