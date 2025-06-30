# Flux

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux automatically applies changes from this repository to your Kubernetes cluster.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Flux Setup](#flux-setup)
- [Resources Managed](#resources-managed)
- [Runtimes](#runtimes)

## Prerequisites

Before using this repository, ensure you have:

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **Flux CLI**: [Install the Flux CLI](https://fluxcd.io/docs/installation/).
- **Git**: [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).
- **Kubectl**: [Install kubectl](https://kubernetes.io/docs/tasks/tools/).
- **Talosctl**: [Install Talosctl](https://www.talos.dev/v1.10/talos-guides/install/talosctl/)

## Flux Setup

Flux manages the deployment of Kubernetes resources in this repository. Key resources:

- **GitRepository**: Specifies the Git repository, branch, and sync interval for Flux.
- **Kustomization**: Defines which paths and resources Flux applies to the cluster.

## Resources Managed

The following resources are managed through Flux in this repository:

- [x] **Actions Runner Controller**
- [X] **Authentik**
- [x] **Bazarr**
- [x] **BuildKit**
- [x] **Cert Manager**
- [x] **Cilium**
- [X] **Cloudflared**
- [x] **Egress Gateway Helper**
- [x] **EmulatorJS**
- [ ] **Envoy Gateway**
- [x] **Falco**
- [ ] **Filebrowser**
- [x] **Flaresolverr**
- [x] **Grafana**
- [X] **Harbor**
- [x] **Headlamp**
- [x] **Heimdall**
- [x] **Home Assistant**
- [ ] **Huntarr**
- [x] **Intel GPU Plugin**
- [x] **Janitorr**
- [x] **Jellyfin**
- [x] **Jellyseerr**
- [x] **Jellystat**
- [ ] **Kyverno**
- [x] **Kubelet CSR Approver**
- [x] **LlamaCPP**
- [ ] **Loki**
- [ ] **MCPMSH**
- [x] **MindsDB**
- [x] **Nix2Container**
- [x] **NzbGet**
- [x] **Prometheus**
- [x] **Prowlarr**
- [x] **Radarr**
- [x] **Redbot**
- [x] **Reflector**
- [x] **Requestrr**
- [ ] **Renovate**
- [x] **Rook**
- [x] **rTorrent**
- [x] **Sonarr**
- [ ] **SonarQube**
- [x] **Suwayomi**
- [ ] **Syncthing**
- [x] **Talos Debug**
- [x] **Tdarr**
- [ ] **Tempo**
- [x] **Traefik**
- [ ] **Trivy**
- [x] **Vector**
- [ ] **Wizarr**

## Runtimes

These are the runtimes used in this repository:

- **Container Runtimes**
  - **Default**: `runc`
  - **Experimental** `youki` (Experimental replacement for runc)
  - **Security**: `kata`
