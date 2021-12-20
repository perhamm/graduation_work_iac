# Configure the Google Cloud tfstate file location
terraform {
  backend "gcs" {
    bucket = "s015937-terraform-state"
    prefix = "terraform"
    credentials = "terraform.json"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.4.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
  required_version = "= 1.1.1"
}
