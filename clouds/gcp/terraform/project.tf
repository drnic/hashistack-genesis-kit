variable "network"              { default = "10.0" }
variable "google_network_name" { default = "hashistack" }
variable "google_region" { default = "europe-west1" }
variable "google_zone_1" { default = "b" }
variable "google_project" {}

provider "google" {
    project     = "${var.google_project}"
    region      = "${var.google_region}"
}

resource "google_compute_network" "default" {
  name = "${var.google_network_name}"
}
output "google.network.name" {
  value = "${google_compute_network.default.name}"
}
