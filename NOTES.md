# Notes for the Talos Kubernetes Cluster

## Talos

Image

```bash
factory.talos.dev/installer/303e821d35b80491f4aecc472c3aab239cf1916a1d4e71f283a5cf164f3a0dfd:v1.9.5
```

## SOPS

How to encrypt the secrets.yaml file with SOPS

```bash
sops --encrypt --age age1mvx2tgja4uztmjrdnfp5m2vlf3j7saj9lynzvyauhmrjvkzu2u4s7sf387 --encrypted-regex '^(data|stringData)$' secrets.yaml > secrets.enc.yaml
```
