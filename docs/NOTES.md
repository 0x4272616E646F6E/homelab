# Notes

## Kubernetes

**Clean up Error Pods**
```bash
kubectl delete pod --field-selector=status.phase==Failed --all-namespaces
```

**Clean up Completed Pods**
```bash
kubectl delete pod --field-selector=status.phase==Succeeded --all-namespaces
```

**Quick Permissions Fix**
```bash
  kubectl run fix-perms -n media --rm -it --restart=Never --image=busybox \
    --overrides='{
      "spec": {
        "containers": [{
          "name": "fix-perms",
          "image": "busybox",
          "command": ["sh", "-c", "chown -R 1000:1000 /config && echo done"],
          "volumeMounts": [{"name": "config", "mountPath": "/config"}],
          "securityContext": {"runAsUser": 0}
        }],
        "volumes": [{"name": "config", "persistentVolumeClaim": {"claimName": "jellyseerr-config"}}]
      }
    }'
```

**Postgres Backup and Restore**
```bash
# Backup (all databases)
kubectl exec -n ns pod -- pg_dumpall -U user > backup.sql

# Backup (single database)
kubectl exec -n ns pod -- pg_dump -U user dbname > backup.sql

# Backup (compressed with timestamp)
kubectl exec -n ns pod -- pg_dumpall -U user | gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz

# Restore (all databases - use postgres db)
kubectl exec -i -n ns pod -- psql -U user -d postgres < backup.sql

# Restore (single database)
kubectl exec -i -n ns pod -- psql -U user -d dbname < backup.sql

# Restore (from compressed)
gunzip < backup.sql.gz | kubectl exec -i -n ns pod -- psql -U user -d postgres

# Verify backup integrity
kubectl exec -n ns pod -- pg_dumpall -U user | head -20

# Copy backup from pod to local
kubectl cp ns/pod:/tmp/backup.sql ./backup.sql

# ⚠️  Important Notes:
# - pg_dumpall requires superuser (typically 'postgres' user)
# - Restore drops and recreates databases (destructive!)
# - For large DBs, use --compress=9 or pipe through gzip
# - Always test restores in non-production first
```

**Copy Local Files to Pod**
```bash
# copy local to pod
kubectl cp ./local.file ns/pod:/app/local.file -c container1

# copy dir recursively
kubectl cp ./dist ns/pod:/var/www/dist -c container1
```

**Drain Node**
```bash
kubectl drain talos-4m3-8nj \
  --ignore-daemonsets \
  --delete-emptydir-data
```

**Uncordon Node**
```bash
kubectl uncordon talos-4m3-8nj
```

**Set Scale Replica**
```bash
# scale to 0 or greater
kubectl scale deployment pod -n ns --replicas=0
```

## Talos
**Installer Image**
The Talos installer image is used to bootstrap and install the Talos operating system on your nodes. Below is the specific image version being used:

```bash
  factory.talos.dev/nocloud-installer/df161ca9e93cc8c47bf4af62e0eb06c4c40323c51c8883ded75006d59c55b81b:v1.14.2
```

- **Image Source**: The image is hosted on `factory.talos.dev`, which is the official Talos image repository.
- **Version**: `v1.14.2` (Kubernetes v1.36.3, kernel 6.18.54-talos).
- **Platform**: `nocloud` — the node reads its machine config from the Proxmox cloud-init
  snippet `local-pve:snippets/controlplane.yaml` (`/zfs/pve/snippets/controlplane.yaml`),
  which is the source of truth. Use the `nocloud-installer` image, **not** the plain
  `installer`, which is the metal variant.
- **Bootloader**: systemd-boot with UKI since the 2026-08-20 rebuild
  (`bootedWithUKI: true`). The `EFI` partition is 2101 MiB, sized for two UKIs at
  ~556 MiB each. Nodes installed before Talos 1.11 had a 1000 MiB GRUB `BOOT` partition
  which cannot hold two modern boot slots, and it is not resizable — a reinstall is the
  only remedy. The `BIOS` and `BOOT` partitions were removed on 2026-10-08; the layout is
  now `EFI / META / STATE / EPHEMERAL`.
- **Upgrades**: pass `--drain=false`. On a single node the default drain deadlocks on
  PodDisruptionBudgets (`coredns-vpn` has `minAvailable: 1` with 0 allowed disruptions),
  leaving the node cordoned with DNS down.

You can use this image to PXE boot or manually install Talos on your nodes.

**Talos Image Upgrade**
```bash
talosctl upgrade -n ${NODE_IP} --image factory.talos.dev/nocloud-installer/${IMAGE_HASH}:${IMAGE_VERSION}
```

**Talos Kubernetes Upgrade**
```bash
# Validate
talosctl --nodes 10.0.0.250 upgrade-k8s --to 1.34.3 --dry-run

# Run
talosctl --nodes 10.0.0.250 upgrade-k8s --to 1.34.3
```

**ETCD Backup**
```bash
talosctl -n 10.0.0.250 etcd snapshot etcd.snapshot
```

**ETCD Restore**
```bash
talosctl -n 10.0.0.250 bootstrap --recover-from ./etcd.snapshot
```

**ETCD Defrag**
```bash
talosctl -n talos-4m3-8nj etcd defrag
```

## SOPS
**Encrypting Secrets with SOPS**
[SOPS](https://github.com/getsops/sops) is a tool for managing encrypted files, commonly used for encrypting Kubernetes secrets. To encrypt your `secrets.yaml` file, use the following command:

```bash
sops --encrypt --age age1mvx2tgja4uztmjrdnfp5m2vlf3j7saj9lynzvyauhmrjvkzu2u4s7sf387 --encrypted-regex '^(data|stringData)$' secrets.yaml > secrets.enc.yaml
```

1. **`--encrypt`**: Specifies that the file should be encrypted.
2. **`--age age1mvx2tgja4uztmjrdnfp5m2vlf3j7saj9lynzvyauhmrjvkzu2u4s7sf387`**: Uses the provided Age public key for encryption. Replace this key with your own Age key if necessary.
3. **`--encrypted-regex '^(data|stringData)$'`**: Ensures that only the `data` and `stringData` fields in the YAML file are encrypted, leaving other fields (like metadata) unencrypted for readability.
4. **`secrets.yaml`**: The input file containing your unencrypted secrets.
5. **`> secrets.enc.yaml`**: Outputs the encrypted file to `secrets.enc.yaml`.

**Best Practices**
- Store the encrypted file (`secrets.enc.yaml`) in version control, but never store the unencrypted file (`secrets.yaml`).
- Ensure that only authorized users have access to the Age private key required for decryption.

## Flux
Flux manages the deployment of Kubernetes resources in this repository. Key resources:

- **GitRepository**: Specifies the Git repository, branch, and sync interval for Flux.
- **HelmRepository**: Specifies the helm repository, type, and interval for Flux.
- **Kustomization**: Defines which paths and resources Flux applies to the cluster.

## Terraform

**⚠️ Terraform cannot produce a bootable control plane — as of 2026-10-08**

`terraform/modules/talos` has not managed the live node since the 2026-08-20 manual
rebuild. A `drift_guard` tripwire fails any plan until `allow_apply_despite_drift = true`
is set. Do not set it before reconciling.

The dangerous part is subtle: `cluster_api_server` sets
`--audit-webhook-config-file=/etc/kubernetes/audit-webhook/webhook.yaml` and mounts
`/var/lib/kube-apiserver-audit`, but `machine_patch` assembles only `network, kubelet,
features, nodeLabels, install, disks, kernel, sysctls, sysfs, time, registries` — there is
**no `files` section**, so `webhook.yaml` is never created and kube-apiserver treats a
missing audit webhook config as fatal at startup. The file exists today (240 bytes) only
because `machine.files` in the snippet created it, and it lives on EPHEMERAL, so it
survives reboots but not a wipe.

| Item | terraform | live | If applied |
|---|---|---|---|
| `machine.files` webhook.yaml | **absent** | present | kube-apiserver fails to start |
| `talos_version` | `v1.12.2` | v1.14.2 | 2-minor downgrade |
| `kubernetes_version` | `v1.35.0` | v1.36.3 | **k8s downgrade — unsupported** |
| installer image | `installer/` (metal) | `nocloud-installer/` | wrong platform variant |
| `machine.disks` `/dev/sdb` | present | removed | reintroduces reformat-hazard config |
| `ExistingVolumeConfig` + `mount.secure: false` | absent | present | volume remounts `noexec`, redbot breaks |
| `bios = "ovmf"` + `efidisk0` | absent | present | may revert firmware to SeaBIOS |
| kubelet `serializeImagePulls`, `maxParallelImagePulls` | absent | present | serialised image pulls |
| cm `node-monitor-grace-period`, `terminated-pod-gc-threshold`, `leader-elect-*` | absent | present | reverts to defaults |
| scheduler `leader-elect-*` | absent | present | reverts to defaults |
| `timeouts { }` at `modules/talos/main.tf:41` | block syntax | — | **does not validate** under talos provider 0.12; must become `timeouts = { }` |
| provider constraint | `root.hcl` `~> 0.9` vs `versions.tf` `~> 0.12` | — | resolves to `>= 0.12, < 1.0`; should agree |

Talos 1.14 deprecates nearly every `v1alpha1` field this module uses, so reconciling to
the current schema means rewriting into multi-document configs. Worth doing once,
alongside the planned migration of terraform state off AWS Lightsail.

Terraform defines and provisions infrastructure as code. In this repo, we run Terraform via OpenTofu to provision the underlying pieces the Kubernetes cluster depends on, while Flux manages the in-cluster manifests.

Layout:
- `terraform/main.tf` wires stacks
- `terraform/modules/` holds reusable modules

How to run with OpenTofu — **blocked by the drift guard above; read it first**:
```sh
cd terraform
tofu init
tofu plan -var-file=homelab.tfvars
tofu apply -var-file=homelab.tfvars
```

## Runtimes
These are the runtimes used in this cluster:

- **Container Runtimes**
  - **Default**: `runc`
  - **Alternatives** `crun` & `youki`
  - **GPU** `nvidia`