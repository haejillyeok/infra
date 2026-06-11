provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  name = var.project
  ssh_keys = join("\n", compact([
    "${var.ssh_username}:${var.ssh_public_key}",
    "${var.deploy_username}:${var.deploy_ssh_public_key}",
    var.agent_ssh_public_key == "" ? "" : "${var.deploy_username}:${var.agent_ssh_public_key}"
  ]))

  labels = {
    project    = var.project
    managed_by = "terraform"
  }

  required_services = toset([
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ])
}

data "google_compute_image" "ubuntu" {
  family  = var.ubuntu_image_family
  project = var.ubuntu_image_project
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "this" {
  name                    = "${local.name}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "app" {
  name                     = "${local.name}-app-subnet"
  ip_cidr_range            = var.app_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_service_access" {
  name          = "${local.name}-private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_cidr_prefix_length
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}

resource "google_compute_firewall" "ssh" {
  name    = "${local.name}-allow-ssh"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${local.name}-ssh"]
}

resource "google_compute_address" "vm" {
  name         = "${local.name}-vm-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_instance" "vm" {
  name         = "${local.name}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["${local.name}-ssh"]
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.self_link

    access_config {
      nat_ip = google_compute_address.vm.address
    }
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_sql_database_instance" "postgres" {
  name             = "${local.name}-postgres"
  region           = var.region
  database_version = var.database_version

  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = "ZONAL"
    disk_size         = var.disk_size_gb
    disk_type         = "PD_HDD"
    disk_autoresize   = false

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.this.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }

  depends_on = [google_service_networking_connection.private_service_access]
}

resource "google_sql_user" "app" {
  name     = var.db_username
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
