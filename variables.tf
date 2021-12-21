# GCP variables

variable "region" {
  default     = "europe-west3"
  description = "Region of resources"
}

variable "project_id" {
  default     = ""
  description = "Project id"
}

variable "bucket_name" {
  default     = "s015937-terraform-state"
  description = "Name of the google storage bucket"
}

variable "name" {
  default = "prod"
}

# Network variables

variable "subnet_cidr" {
  default = "10.10.0.0/24"

  description = "Subnet range"
}

# Cloud SQL variables

variable "availability_type" {
  default = "ZONAL"
  description = "Availability type for HA"
}

variable "sql_instance_size" {
  default     = "db-custom-1-3840"
  description = "Size of Cloud SQL instances"
}

variable "sql_disk_type" {
  default     = "PD_HDD"
  description = "Cloud SQL instance disk type"
}

variable "sql_disk_size" {
  default     = "10"
  description = "Storage size in GB"
}

variable "sql_require_ssl" {
  default     = "false"
  description = "Enforce SSL connections"
}

variable "sql_master_zone" {
  default     = "a"
  description = "Zone of the Cloud SQL master (a, b, ...)"
}

# variable "sql_replica_zone" {
#   default     = "b"
#   description = "Zone of the Cloud SQL replica (a, b, ...)"
# }

variable "sql_connect_retry_interval" {
  default     = 60
}

variable "sql_user" {
  default     = "postgres"
}

variable "sql_pass" {
  default     = ""
}

# GKE variables

variable "min_master_version" {
  default     = "1.21.5-gke.1302"
}

variable "node_version" {
  default     = "1.21.5-gke.1302"
}

variable "gke_num_nodes" {
  default = 1
}

variable "gke_node_machine_type" {
  default     = "n1-standard-1"
}

variable "gke_label" {
  default     = "prod"
}

variable "vmname" {
  default     = "gitlab-runner"
  description = "gitlab-runner"
  type = string
}

variable "gitlab_runner_registration_token" {
  default     = ""
  description = "gitlab_runner_registration_token"
  type = string
}