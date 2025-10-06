# Notes

## Kubernetes

**Turn vLLM ON, ComfyUI OFF**
```bash
kubectl -n development create configmap gpu-app-config \
  --from-literal=COMFY_REPLICAS=0 \
  --from-literal=VLLM_REPLICAS=1 \
  -o yaml --dry-run=client | kubectl apply -f -
```

**Turn ComfyUI ON, vLLM OFF**
```bash
kubectl -n development create configmap gpu-app-config \
  --from-literal=COMFY_REPLICAS=1 \
  --from-literal=VLLM_REPLICAS=0 \
  -o yaml --dry-run=client | kubectl apply -f -
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
 factory.talos.dev/nocloud-installer/00cd01c7b8612cfd0c5e4394a20fe0c12b1c398ddbf6b554d909179411659e6a:v1.11.1 
```

**Extensions**
```bash
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/crun
            - siderolabs/gasket-driver
            - siderolabs/nonfree-kmod-nvidia-production
            - siderolabs/nvidia-container-toolkit-production
            - siderolabs/qemu-guest-agent
            - siderolabs/util-linux-tools
            - siderolabs/youki
```

- **Image Source**: The image is hosted on `factory.talos.dev`, which is the official Talos image repository.
- **Version**: The version `v1.11.1` corresponds to a specific release of Talos. Ensure that all nodes in your cluster are using the same version to avoid compatibility issues.

You can use this image to PXE boot or manually install Talos on your nodes.

**Talos Image Upgrade**
```bash
talosctl upgrade -n ${NODE_IP} --image factory.talos.dev/nocloud-installer/${IMAGE_HASH}:${IMAGE_VERSION}
```

**Talos Kubernetes Upgrade**
```bash
# Validate
talosctl --nodes 10.0.0.250 upgrade-k8s --to 1.34.1 --dry-run

# Run
talosctl --nodes 10.0.0.250 upgrade-k8s --to 1.34.1
```

**ETCD Backup**
```bash
talosctl -n 10.0.0.250 etcd snapshot etcd.snapshot
```

**ETCD Restore**
```bash
talosctl -n 10.0.0.250 bootstrap --recover-from ./etcd.snapshot
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
Terraform defines and provisions infrastructure as code. In this repo, we run Terraform via OpenTofu to provision the underlying pieces the Kubernetes cluster depends on, while Flux manages the in-cluster manifests.

Layout:
- `terraform/main.tf` wires stacks
- `terraform/modules/` holds reusable modules

How to run with OpenTofu:
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