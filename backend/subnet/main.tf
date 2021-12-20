# Create Subnet

resource "google_compute_subnetwork" "subnet" {
  name          = "prod-subnet"
  ip_cidr_range = "${var.subnet_cidr}"
  network       = "${var.vpc_name}"
  region        = "${var.region}"
}
