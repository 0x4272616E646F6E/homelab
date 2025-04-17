# Notes for the Talos Kubernetes Cluster

## Longhorn

### Skip Finalizers

When attempting to delete the Longhorn namespace, you may encounter issues where finalizers get stuck. Finalizers are Kubernetes resources that prevent the deletion of an object until certain cleanup tasks are completed. If these finalizers are stuck, they can block the deletion process.

To forcefully remove the finalizers and delete the namespace, you can use the following command:

```bash
kubectl get namespace longhorn-system -o json \
| jq 'del(.spec.finalizers)' \
| kubectl replace --raw "/api/v1/namespaces/longhorn-system/finalize" -f -
```

1. **`kubectl get namespace longhorn-system -o json`**: Retrieves the `longhorn-system` namespace in JSON format.
2. **`jq 'del(.spec.finalizers)'`**: Uses `jq` to delete the `finalizers` field from the namespace specification.
3. **`kubectl replace --raw`**: Replaces the namespace resource on the Kubernetes API server with the modified JSON, effectively removing the finalizers and allowing the namespace to be deleted.

Use this command with caution, as it bypasses the normal cleanup process.

## Talos

### Talos Installer Image

The Talos installer image is used to bootstrap and install the Talos operating system on your nodes. Below is the specific image version being used:

```bash
factory.talos.dev/installer/303e821d35b80491f4aecc472c3aab239cf1916a1d4e71f283a5cf164f3a0dfd:v1.9.5
```

- **Image Source**: The image is hosted on `factory.talos.dev`, which is the official Talos image repository.
- **Version**: The version `v1.9.5` corresponds to a specific release of Talos. Ensure that all nodes in your cluster are using the same version to avoid compatibility issues.

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
