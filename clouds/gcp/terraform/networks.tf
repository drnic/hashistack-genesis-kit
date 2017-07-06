resource "google_compute_subnetwork" "servers" {
  name          = "${var.google_network_name}-servers"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "${var.network}.2.0/24"
  region        = "${var.google_region}"
}

output "google.subnetwork.servers.name" {
  value = "${google_compute_subnetwork.servers.name}"
}

resource "google_compute_subnetwork" "nodes" {
  name          = "${var.google_network_name}-nodes"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "${var.network}.3.0/24"
  region        = "${var.google_region}"
}
output "google.subnetwork.nodes.name" {
  value = "${google_compute_subnetwork.nodes.name}"
}
