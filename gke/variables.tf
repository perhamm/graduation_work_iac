# GKE variables

variable "region" {
  description = "Region of resources"
}

variable "min_master_version" {
  description = "Number of nodes in each GKE cluster zone"
}

variable "node_version" {
  description = "Number of nodes in each GKE cluster zone"
}

variable "gke_num_nodes" {
  description = "Number of nodes in each GKE cluster zone"
}

variable "vpc_name" {
  description = "vpc name"
}
variable "subnet_name" {
  description = "subnet name"
}



variable "gke_node_machine_type" {
  description = "Machine type of GKE nodes"
}

# k8s variables
variable gke_label {
  description = "label"
}
