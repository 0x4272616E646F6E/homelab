# Flux

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux continuously monitors this repository and automatically applies changes to your Kubernetes cluster.

## Table of Contents

- [Flux](#flux)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Flux Setup](#flux-setup)
  - [Resources Managed](#resources-managed)
  - [Runtimes](#runtimes)

## Prerequisites

Before using this repository, ensure that you have the following:

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **Flux CLI**: Install the Flux CLI.
- **Git**: You should have Git installed to clone and manage the repository.
- **Kubectl**: To interact with the Kubernetes cluster.

## Flux Setup

This repository uses Flux to manage the deployment of Kubernetes resources. Flux continuously watches this repository for changes and automatically applies them to the cluster. Here’s a breakdown of how Flux is set up in this repository:

- GitRepository: A custom Flux resource that tells Flux where the Git repository is located, which branch to track, and the synchronization interval.
- Kustomization: A Flux resource used to define what paths and resources to apply to the cluster.

These resources are defined in the following files:

- flux-system/flux-gitrepository.yaml - Defines the Git repository for Flux to track.
- flux-system/flux-kustomization.yaml - Defines the Kustomization to apply the manifests located in this repository.

## Resources Managed

The following resources are managed through Flux in this repository:

- [x] **Actions Runner Controller**
- [X] **Authentik**
- [x] **Bazarr**
- [x] **Cert Manager**
- [x] **Cilium**
- [X] **Cloudflared**
- [x] **Egress Gateway Helper**
- [ ] **EmulatorJS**
- [x] **Falco**
- [x] **Flaresolverr**
- [x] **Grafana**
- [X] **Harbor**
- [ ] **Headlamp**
- [x] **Heimdall**
- [x] **Home Assistant**
- [x] **Intel GPU Plugin**
- [x] **Janitorr**
- [x] **Jellyfin**
- [x] **Jellyseerr**
- [x] **Jellystat**
- [ ] **Kyverno**
- [x] **Kubelet CSR Approver**
- [ ] **Loki**
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
- [x] **Seafile**
- [x] **Sonarr**
- [ ] **SonarQube**
- [x] **Suwayomi**
- [x] **Talos Debug**
- [ ] **Tempo**
- [x] **Traefik**
- [ ] **Trivy**
- [x] **Vector**

## Runtimes

These are the runtimes used in this repository:

- **Container Runtimes**
  - **Default**: `runc` will be `youki` after release.
  - **Security**: `kata`
