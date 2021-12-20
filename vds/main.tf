resource "google_compute_instance" "vm" {
  name         = var.vmname
  machine_type = "n1-standard-1"
  zone         = "${var.region}-a"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  
  network_interface {
    network            = "${var.vpc_name}"
    subnetwork         = "${var.subnet_name}"
    access_config {
    }
  }
    
  tags = ["gitlab-runner"] 
   


  metadata_startup_script = <<-EOF
  sudo apt -y update
  EOF
}

