variable "db_depends_on" {
  description = "A single resource that the database instance depends on"
  type        = any
}

# GCP variables
variable "region" {
  description = "Region of resources"
}

# Cloud SQL variables

variable "availability_type" {
  description = "Availability type for HA"
}

variable "sql_instance_size" {
  description = "Size of Cloud SQL instances"
}

variable "sql_disk_type" {
  description = "Cloud SQL instance disk type"
}

variable "sql_disk_size" {
  description = "Storage size in GB"
}

variable "sql_require_ssl" {
  description = "Enforce SSL connections"
}

variable "sql_connect_retry_interval" {
  description = "The number of seconds between connect retries."
}

variable "sql_master_zone" {
  description = "Zone of the Cloud SQL master (a, b, ...)"
}

# variable "sql_replica_zone" {
#   description = "Zone of the Cloud SQL replica (a, b, ...)"
# }

variable "sql_user" {
  description = "Username of the host to access the database"
}

variable "sql_pass" {
  description = "Password of the host to access the database"
}


variable "authorized_networks" {
  default = [{
    name  = "all"
    value = "0.0.0.0/0"
  }]
  type        = list(map(string))
  description = "List of mapped public networks authorized to access to the instances. "
}


variable "vpc_link" {
  description = "A link to the VPC where the db will live (i.e. google_compute_network.some_vpc.self_link)"
  type        = string
}
