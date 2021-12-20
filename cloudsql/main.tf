resource "random_id" "id" {
  byte_length = 4
  prefix      = "sql-prod-"
}

resource "google_sql_database_instance" "master" {
#  name             = "sql-${terraform.workspace}-master"
  name             = "${random_id.id.hex}"
  region           = "${var.region}"
  database_version = "POSTGRES_10"
  depends_on       = [var.db_depends_on]
  deletion_protection = false
  settings {
    availability_type = "${var.availability_type}"
    tier              = "${var.sql_instance_size}"
    disk_type         = "${var.sql_disk_type}"
    disk_size         = "${var.sql_disk_size}"
    disk_autoresize   = false

    ip_configuration {
      ipv4_enabled = false
      private_network = "${var.vpc_link}"
      require_ssl  = "${var.sql_require_ssl}"
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }


      
    }

    location_preference {
      zone = "${var.region}-${var.sql_master_zone}"
    }

#     backup_configuration {
# #      binary_log_enabled = true
#       enabled            = true
#       start_time         = "00:00"
#     }
  }
}

# resource "google_sql_database_instance" "replica" {
#   depends_on = [
#     "google_sql_database_instance.master",
#   ]

#   name                 = "metest-prod-replica"
#   count                = "1"
#   region               = "${var.region}"
#   database_version     = "POSTGRES_10"
#   master_instance_name = "${google_sql_database_instance.master.name}"

#   settings {
#     tier            = "${var.sql_instance_size}"
#     disk_type       = "${var.sql_disk_type}"
#     disk_size       = "${var.sql_disk_size}"
#     disk_autoresize = true

#     location_preference {
#       zone = "${var.region}-${var.sql_replica_zone}"
#     }
#   }
# }

resource "google_sql_user" "user" {
  depends_on = [
    google_sql_database_instance.master,
  #  google_sql_database_instance.replica,
  ]

  instance = "${google_sql_database_instance.master.name}"
  name     = "${var.sql_user}"
  password = "${var.sql_pass}"
}
