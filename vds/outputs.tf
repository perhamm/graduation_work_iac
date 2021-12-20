output "external_ip_vm" {
  value = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}

output "internal_ip_vm" {
  value = google_compute_instance.vm.network_interface.0.network_ip
}

