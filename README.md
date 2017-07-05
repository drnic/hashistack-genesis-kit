# hashistack genesis kit

This genesis kit will by default deploy a 3 node cluster of consul servers.
By turning on subkits vault and nomad additional jobs will be added to the main servers and nodes running nomad agents will be deployed.

## Deployment on Warden

This will walk through setting up a complete hashistack deployment on a pre-deployed BOSH on VirtualBox (most of it is independant of the CPI)

### Preparation

You will need to clone this genesis kit to use some helper scripts:
```
git clone https://github.com/genesis-community/hashistack-genesis-kit.git
```

Make sure you have a bosh environment called warden:
```
$ bosh2 environments
URL           Alias
192.168.50.6  warden

1 environments

Succeeded
```

Upload the [cloud-config](./clouds/warden/cloud-config.yml) from this repository.
```
$ export BOSH_ENVIRONMENT=warden
$ bosh2 ucc cloud-config.yml
```

Before deploying lets make sure a dev vault is accessible in another terminal:
```
$ vault server -dev
(...)
Unseal Key: hhN3p/gH4wza9XhyxVrCT7GdTdLs8kFkemctznSDiM8=
Root Token: b65c38a5-9a14-394a-c89f-8e1f97dd574e
(...)
```

Back in the original terminal:
```
$ safe target http://localhost:8200 local
Now targeting local at http://localhost:8200

$ safe auth token
Authenticating against local at http://localhost:8200
Token: b65c38a5-9a14-394a-c89f-8e1f97dd574e
$ safe set secret/handshake hello=world
hello: world
```

### Creating the environment

Then take genesis for a spin
```
$ genesis init --kit hashistack
$ cd hashistack-deployments
$ genesis new warden
```

When it asks for the encryption keys to consul / nomad you can generate them with:
```
$ consul keygen
Rt1ueEJfsdesOKbFJ3vduw==
```

Then continue with the actual deployment:
```
$ genesis deploy warden.yml
```

Once this is done you should have 3 server nodes and 3 nomad agent nodes.
You take a look at the traefik and consul uis via:

```
$ open https://10.244.2.2.xip.io:8080
$ open https://consul.10.244.2.2.xip.io:8080
```

Skip the security notice due to the self-signed certs. The http basic auth is `admin:admin` (for now, needs generating via kit).

The Consul ui will show that vault is failing because it is sealed.

### Setting up Vault

Lets unseal Vault and setup the integration between Nomad and Vault.

```
$ export VAULT_ADDR=https://10.244.1.2:8200
$ export VAULT_SKIP_VERIFY=1
$ vault init > keys
```

Use the [unseal script](./bin/unseal) from this repo to unseal all vaults with this one-liner:
```
$ cat keys | ../hashistack-genesis-kit/bin/unseal https://10.244.1.2:8200 https://10.244.1.3:8200 https://10.244.1.4:8200
```

Then we will create some policies and roles to enable integration between Nomad and Vault using terraform

```
$ cat keys | grep Token
Initial Root Token: 8490ad43-8dae-0c93-2503-b0f151213312
$ export VAULT_TOKEN=8490ad43-8dae-0c93-2503-b0f151213312
$ terraform plan ../hashistack-genesis-kit/vault/
$ terraform apply ../hashistack-genesis-kit/vault/
```
### Vault Nomad integration

Now that the policies are in place we will create a token for Nomad and set it in our _local_ dev vault.
```
$ vault token-create -policy="nomad-server" -display-name="nomad-server"
Key             Value
---             -----
token           7fcddbaf-7a8a-e926-d099-324c2d4151ef
token_accessor  2dcc97b8-245b-d17d-b1e0-61fe4f9d1cab
token_duration  768h0m0s
token_renewable true
token_policies  [default nomad-server]
$ VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=b65c38a5-9a14-394a-c89f-8e1f97dd574e \
safe set secret/warden/hashistack/nomad/vault token=7fcddbaf-7a8a-e926-d099-324c2d4151ef
```

### Zero-Downtime Vault

Before upgrading nomad with the vault token we will setup vault for zero downtime deployments. It would be very stupid if vault would not be accessible to apps scheduled on nomad during every upgrade. The problem is that everytime Vault is restarted each node requires unsealing. To perform this automattically we must expose the unseal keys in our deployment manifest.

*WARNING* Once you have performed the upgrade please `vault rekey` to generate new unseal keys!! Otherwise it is possible to decrypt and see all secrets by anyone with access to the manifest.

First we will create a step-down token that can be used to gracefully fail over Vault:

```
$  vault token-create -policy="step-down" -display-name="step-down" -no-default-policy -orphan
Key             Value
---             -----
token           8ed3a20d-714a-8fc1-46d5-67a06fae7cb0
token_accessor  d2349a6a-77b7-39aa-a854-abd69a17df68
token_duration  768h0m0s
token_renewable true
token_policies  [step-down]
```

Then we will add the step down token and unseal keys to the warden.yml that genesis generated:
```
$ vi warden.yml
params:
  vault_step_down_token: "8ed3a20d-714a-8fc1-46d5-67a06fae7cb0"
  vault_unseal_keys:
  - ixJFebM2otyYrgEiFBge9Q5DZquzAZDoJNeOHPyp95AZ
  - aVkFP6JbpsGW5LrMCrL2W/oN6mIL05oq99AdV9CBmHoS
  - vaxpfn3VaMcPs7RQHC5FTxnpqy/ccFf+YTYfIHJh0iz7
```

Now we can redeploy to complete the Nomad setup:
```
$ VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=b65c38a5-9a14-394a-c89f-8e1f97dd574e genesis deploy warden.yml
(...)
  properties:
    nomad:
      vault:
-       token: "<redacted>"
+       token: "<redacted>"
    vault:
      update:
-       step_down_token: "<redacted>"
+       step_down_token: "<redacted>"
        unseal_keys:
+       - "<redacted>"
+       - "<redacted>"
+       - "<redacted>"

Continue? [yN]: y
```

Finally once the deployment is completed you can rekey with the help of the [rekey script](./bin/rekey) to invalidate the unseal keys in the manifest.
```
$ cat keys | ../hashistack-genesis-kit/bin/rekey


Key 1: Fob1ffKR4v8CR8sBFndk4V13uKa2dzqoR6Ucv/FxSMP6
Key 2: eET0b955YAanX3l6DbZJVJJbLRKDhwJaqUdDu22DDVQ5
Key 3: RtUKkVsqdofbbDLeX8LOmpRMUhiEn62+MXV7/E+bda4I
Key 4: 4z7ikYozpVYkrzXCj5tmTk5n+8n2dQGR/R6gi/IlqVaJ
Key 5: Bd2pxy3QANmgcWNIlx0ydKLXLX8FU9OI7t8zq8+EIjeA

Operation nonce: 1dd93ddf-b726-1aef-0c36-39242cd7e516

Vault rekeyed with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your vault will remain permanently sealed.
```

The next time you try to deploy the deployment will fail due to the old unseal keys. You can choose one of
- remove the unseal keys and unseal manually once the deployment has completed (non-ha)
- add the new unseal keys to the manifest and rekey once again

### Deploying the hashi-ui

To complete the tour lets deploy a job onto Nomad
```
$ export NOMAD_ADDR=https://10.244.1.2:4646
$ export NOMAD_SKIP_VERIFY=1
$ nomad node-status
ID        DC      Name    Class   Drain  Status
643fd1c3  warden  node/2  <none>  false  ready
6d8508db  warden  node/1  <none>  false  ready
16427242  warden  node/0  <none>  false  ready
$ nomad run ../../hashistack-genesis-kit/nomad/hashi-ui.hcl
==> Monitoring evaluation "4576a956"
    Evaluation triggered by job "hashi-ui"
    Allocation "3abee56d" created: node "643fd1c3", group "server"
    Allocation "951d3aab" created: node "6d8508db", group "server"
    Allocation "ae32979c" created: node "16427242", group "server"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "4576a956" finished with status "complete"
```

Then after the docker containers have downloaded:
```
$ nomad status
hashi-ui  service  50        running
$ nomad status hashi-ui
ID            = hashi-ui
Name          = hashi-ui
Type          = service
Priority      = 50
Datacenters   = warden
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
server      0       0         3        0       0         0

Allocations
ID        Eval ID   Node ID   Task Group  Desired  Status   Created At
3abee56d  4576a956  643fd1c3  server      run      running  07/05/17 17:30:37 CEST
951d3aab  4576a956  6d8508db  server      run      running  07/05/17 17:30:37 CEST
ae32979c  4576a956  16427242  server      run      running  07/05/17 17:30:37 CEST
$ open https://hashi-ui.10.244.2.2.xip.io:8080
```

Voila the hashi-ui has registered itself with traefik (check `open https://10.244.2.2.xip.io:8080` to see) and is accessible.
