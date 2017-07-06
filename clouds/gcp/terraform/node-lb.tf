resource "google_compute_target_pool" "nodes" {
  name = "nodes"
  session_affinity = "CLIENT_IP"
}

resource "google_compute_address" "nodes" {
  name   = "nodes"
}

resource "google_compute_forwarding_rule" "nodes" {
  name       = "nodes"
  target     = "${google_compute_target_pool.nodes.self_link}"
  ip_address = "${google_compute_address.nodes.address}"
}

output "google.nodes.public_ip" {
  value = "${google_compute_forwarding_rule.nodes.ip_address}"
}
output "google.nodes.target_pool" {
  value = "${google_compute_target_pool.nodes.name}"
}
