variable "region" {
  description = "name of region deployment"
  type = string
}

variable "vpc_name" {
  description = "vpc name"
}
variable "subnet_name" {
  description = "subnet name"
}

variable "vmname" {
  description = "vm name"
  type = string
}

variable "gitlab_runner_registration_token" {
  description = "gitlab_runner_registration_token"
  type = string
}