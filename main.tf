resource "google_compute_network" "this" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
}

output "network_name" {
  value = google_compute_network.this.name
}

module "network" {
  source        = "./modules/network"
}

module "compute_engine" {
  source = "./modules/compute_engine"
}

resource "google_compute_subnetwork" "this" {
  name                     = "subnetwork"
  network                  = google_compute_network.this.id
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "europe-west1"
}

resource "google_compute_firewall" "default-allow-http" {
  name      = "default-allow-http"
  network   = google_compute_network.this.name
  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"] //443 https
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "default-allow-internal" {
  name      = "default-allow-internal"
  network   = google_compute_network.this.name
  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.0.1.0/24"]
}

resource "google_compute_firewall" "default-allow-ssh" {
  name      = "default-allow-ssh"
  network   = google_compute_network.this.name
  priority  = 2000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny-all" {
  name      = "deny-all"
  network   = google_compute_network.this.name
  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

module "sql_database" {
  source = "./modules/sql_database"
  db_password = var.db_password
}

module "repository" {
  source = "./modules/repository"
}

module "cloud_build" {
  source = "./modules/cloud_build"
  project_name = var.project_name
  project_number = var.project_number
  github_app_id = var.github_app_id
  github_key = var.github_key
}

module "cloud_run" {
  source = "./modules/cloud_run"
  project_name = var.project_name
  project_number = var.project_number
  db_password = var.db_password
  cloud_sql_instance = module.sql_database.cloud_sql_instance
}

