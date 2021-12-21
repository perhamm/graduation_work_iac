resource "google_compute_instance" "vm" {
  name         = var.vmname
  machine_type = "g1-small"
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
  sudo apt-get update
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
  dpkg -i gitlab-runner_amd64.deb
  gitlab-runner register   --non-interactive   --url "https://gitlab.com/"   --registration-token "${var.gitlab_runner_registration_token}"   --executor "docker"   --docker-image alpine:latest   --description "docker-runner"   --tag-list "docker"   --run-untagged="true"   --locked="false"   --access-level="not_protected" --docker-volumes /var/run/docker.sock:/var/run/docker.sock
  EOF
}

