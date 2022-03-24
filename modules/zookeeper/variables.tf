variable "config" {
  type = string
}

variable "data_dir" {
  type = string
}

variable "servers" {
  type = number
}

variable "subnet" {
  type = string
}

variable "zones" {
  type = list(string)
}