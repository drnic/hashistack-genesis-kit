resource "google_compute_firewall" "consul-internal" {
  name          = "${var.google_network_name}-consul-internal"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["8300", "8301", "8500"]
  }

  allow {
    protocol = "udp"
    ports = ["8301", "8500"]
  }

  source_tags = ["consul-agent", "consul"]
  target_tags = ["consul", "consul-agent"]
}

resource "google_compute_firewall" "vault-internal" {
  name          = "${var.google_network_name}-vault-internal"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["8201"]
  }

  source_tags = ["vault"]
  target_tags = ["vault"]
}

resource "google_compute_firewall" "vault-external" {
  name          = "${var.google_network_name}-vault-external"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["8200"]
  }

  source_tags = ["bastion", "nomad", "nomad-node"]
  target_tags = ["vault"]
}

resource "google_compute_firewall" "nomad-internal" {
  name          = "${var.google_network_name}-nomad-internal"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["4646", "4647", "4648"]
  }

  source_tags = ["nomad", "nomad-node"]
  target_tags = ["nomad", "nomad-node"]
}

resource "google_compute_firewall" "nomad-jobs" {
  name          = "${var.google_network_name}-nomad-jobs"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["20000-60000"]
  }

  source_tags = ["nomad-node"]
  target_tags = ["nomad-node"]
}

resource "google_compute_firewall" "nomad-external" {
  name          = "${var.google_network_name}-nomad-external"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["4646"]
  }

  source_tags = ["bastion"]
  target_tags = ["nomad"]
}

resource "google_compute_firewall" "nomad-public" {
  name          = "${var.google_network_name}-nomad-public"
  network       = "${google_compute_network.default.name}"

  allow {
    protocol = "tcp"
    ports = ["8080", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["nomad-node"]
}
