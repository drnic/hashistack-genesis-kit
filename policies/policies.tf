provider "vault" {
}

resource "vault_policy" "step-down" {
  name = "step-down"

  policy = "${file("${path.module}/step-down.hcl")}"
}

resource "vault_policy" "nomad-server" {
  name = "nomad-server"
  policy = "${file("${path.module}/nomad-server.hcl")}"
}
