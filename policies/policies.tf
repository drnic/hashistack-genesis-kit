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

resource "vault_policy" "hashi-ui" {
  name = "hashi-ui"
  policy = "${file("${path.module}/hashi-ui.hcl")}"
}
