# network VPC output

output "vpc_name" {
  value       = "${google_compute_network.vpc.name}"
  description = "The unique name of the network"
}

output "link" {
  value       = "${google_compute_network.vpc.self_link}"
  description = "The URL of the created resource"
}

output "private_vpc_connection" {
  description = "The private VPC connection"
  value       = google_service_networking_connection.private_vpc_connection
}