provider "vault" {
}

resource "vault_generic_secret" "nomad-cluster-role" {
  path = "/auth/token/roles/nomad-cluster"

  data_json = "${file("${path.module}/nomad-cluster-role.json")}"
}

resource "vault_policy" "step-down" {
  name = "step-down"

  policy = "${file("${path.module}/step-down-policy.hcl")}"
}

resource "vault_policy" "nomad-server" {
  name = "nomad-server"
  policy = "${file("${path.module}/nomad-server-policy.hcl")}"
}
