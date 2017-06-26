# hashistack genesis kit

This genesis kit will by default deploy a 3 node consul cluster. Optional subkits include vaul and nomad (not yet).

# HA Vault

Vault will be deployed on 2 nodes with HA enabled via consul.

To enable zero-downtime deployments you must provide an auth token that is authorized to perform `vault step-down`. Once you have unsealed vault you can set it up as follows:

```
$ cat > step-down.hcl <<EOF
path "sys/step-down" {
  capabilities = ["update", "sudo"]
}
EOF
$ vault policy-write step-down ./step-down.hcl
Policy 'step-down' written.
$ vault token-create -policy="step-down" -display-name="step-down" -no-default-policy -orphan
Key             Value
---             -----
token           0687a4b0-4305-40da-b668-988abd7d056a
token_accessor  b0da7605-0963-5328-7a8d-cff258c805f3
token_duration  768h0m0s
token_renewable true
token_policies  [step-down]
```

Then add the token value to your deployment file under `params.vault_step_down_token`. This will cause Vault to perform a controlled failover before updating each individual node.

Once the update of a node has completed it will need to be unsealed. If you add your unseal keys under `params.vault_unseal_keys` this will also be taken care of for you which will make the entire update process truely zero downtime ie. when using a consul-agent to provide dns the domain name `vault.service.consul` should always be pointing to a vault that will accept connections.
