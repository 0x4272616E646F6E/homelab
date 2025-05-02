# Notes for the Talos Kubernetes Cluster

## Talos

### Talos Installer Image

The Talos installer image is used to bootstrap and install the Talos operating system on your nodes. Below is the specific image version being used:

```bash
 factory.talos.dev/installer/14941b6873384400733449e4b2f1ddae0efb50be8513f6c6ee6fc9df22766377:v1.11.0-alpha.0
```

### Extensions

```bash
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/fuse3
            - siderolabs/gasket-driver
            - siderolabs/i915
            - siderolabs/intel-ice-firmware
            - siderolabs/intel-ucode
            - siderolabs/kata-containers
            - siderolabs/mei
            - siderolabs/qemu-guest-agent
            - siderolabs/util-linux-tools
            - siderolabs/youki
```

- **Image Source**: The image is hosted on `factory.talos.dev`, which is the official Talos image repository.
- **Version**: The version `v1.11.0-alpha.0` corresponds to a specific release of Talos. Ensure that all nodes in your cluster are using the same version to avoid compatibility issues.

You can use this image to PXE boot or manually install Talos on your nodes.

## SOPS

### Encrypting Secrets with SOPS

[SOPS](https://github.com/getsops/sops) is a tool for managing encrypted files, commonly used for encrypting Kubernetes secrets. To encrypt your `secrets.yaml` file, use the following command:

```bash
sops --encrypt --age age1mvx2tgja4uztmjrdnfp5m2vlf3j7saj9lynzvyauhmrjvkzu2u4s7sf387 --encrypted-regex '^(data|stringData)$' secrets.yaml > secrets.enc.yaml
```

1. **`--encrypt`**: Specifies that the file should be encrypted.
2. **`--age age1mvx2tgja4uztmjrdnfp5m2vlf3j7saj9lynzvyauhmrjvkzu2u4s7sf387`**: Uses the provided Age public key for encryption. Replace this key with your own Age key if necessary.
3. **`--encrypted-regex '^(data|stringData)$'`**: Ensures that only the `data` and `stringData` fields in the YAML file are encrypted, leaving other fields (like metadata) unencrypted for readability.
4. **`secrets.yaml`**: The input file containing your unencrypted secrets.
5. **`> secrets.enc.yaml`**: Outputs the encrypted file to `secrets.enc.yaml`.

#### Best Practices

- Store the encrypted file (`secrets.enc.yaml`) in version control, but never store the unencrypted file (`secrets.yaml`).
- Ensure that only authorized users have access to the Age private key required for decryption.
