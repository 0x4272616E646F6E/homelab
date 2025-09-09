# Notes

## Talos
**Installer Image**
The Talos installer image is used to bootstrap and install the Talos operating system on your nodes. Below is the specific image version being used:

```bash
 factory.talos.dev/nocloud-installer/12bae1aaa19d63f5ec5f1f2bc316cedfede9506f2b79e7935d563da195e240d1:v1.11.1 
 ```

**Extensions**
```bash
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/fuse3
            - siderolabs/gasket-driver
            - siderolabs/intel-ice-firmware
            - siderolabs/intel-ucode
            - siderolabs/mei
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
talosctl --nodes 10.0.0.250 upgrade-k8s --to 1.34.0 --dry-run

# Run
talosctl --nodes 10.0.0.250 upgrade-k8s --to 1.34.0
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

## CDK
The Cloud Development Kit (CDK) is an open-source software framework that let you define cloud and infrastructure resources using familiar programming languages instead of raw YAML or JSON. This repository uses Java-based CDK variants for Kubernetes and Terraform.

- CDK8s generates Kubernetes manifests from Java code, which Flux then applies.
- CDKTF models infrastructure as code in Java, synthesizes Terraform JSON, and is applied with OpenTofu.

**CDK8s** (Kubernetes, Java)
- Write Kubernetes apps in Java using CDK8s constructs
- Generate YAML and commit for Flux to apply

Workflow:
1. cd cdk/cdk8s
2. mvn -q compile
3. cdk8s synth
4. Commit generated manifests and Flux will reconcile

**CDKTF** (Terraform, Java)
- Define infra stacks in Java; synth produces Terraform JSON in cdktf.out/stacks/<stack-name>
- Apply with OpenTofu or `cdktf deploy`

Workflow:
1. cd cdk/cdktf
2. ./gradlew build
3. cdktf get
4. cdktf synth
5. cd cdktf.out/stacks/<stack-name>
6. tofu init && tofu plan && tofu apply

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
  - **Alternative** `youki`
  - **GPU** `nvidia`
