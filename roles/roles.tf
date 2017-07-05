provider "vault" {
}

resource "vault_generic_secret" "nomad-cluster-role" {
  path = "/auth/token/roles/nomad-cluster"

  data_json = "${file("${path.module}/nomad-cluster.json")}"
}
