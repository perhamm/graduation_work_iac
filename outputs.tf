# remote state output
# output "data_out" {
#   value = "${data.terraform_remote_state.project_id.project_id}"
# }

# Cloud SQL postgresql outputs
output "master_instance_sql_ipv4" {
  value       = "${module.cloudsql.master_instance_sql_ipv4}"
  description = "The IPv4 address assigned for master"
}

# GKE outputs
output "endpoint" {
  value       = "${module.gke.endpoint}"
  description = "Endpoint for accessing the master node"
}


# Gitlab runner ip
output "external_ip_vm" {
  value       = "${module.vds.external_ip_vm}"
  description = "external_ip_vm for gitlab-runner"
}


