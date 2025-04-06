# Flux

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux continuously monitors this repository and automatically applies changes to your Kubernetes cluster.

## Table of Contents

- [Flux](#flux)
	- [Table of Contents](#table-of-contents)
	- [Prerequisites](#prerequisites)
	- [Flux Setup](#flux-setup)
	- [Resources Managed](#resources-managed)
	- [Contributing](#contributing)
	- [License](#license)

## Prerequisites

Before using this repository, ensure that you have the following:

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **Flux CLI**: Install the Flux CLI.
-	**Git**: You should have Git installed to clone and manage the repository.
-	**Kubectl**: To interact with the Kubernetes cluster.

## Flux Setup

This repository uses Flux to manage the deployment of Kubernetes resources. Flux continuously watches this repository for changes and automatically applies them to the cluster. Here’s a breakdown of how Flux is set up in this repository:

- GitRepository: A custom Flux resource that tells Flux where the Git repository is located, which branch to track, and the synchronization interval.
- Kustomization: A Flux resource used to define what paths and resources to apply to the cluster.

These resources are defined in the following files:

- flux-system/flux-gitrepository.yaml - Defines the Git repository for Flux to track.
- flux-system/flux-kustomization.yaml - Defines the Kustomization to apply the manifests located in this repository.

## Resources Managed

The following resources are managed through Flux in this repository:

- **Authentik**
- **Bazarr**
- **Cert Manager**
- **Cilium**
- **Cloudflared**
- **Falco**
- **Flaresolverr**
- **Gluetun**
- **Grafana**
- **Harbor**
- **Home Assistant**
- **Jellyfin**
- **Jellyseerr**
- **OpenBao**
- **OpebEBS**
- **Paperless-NGX**
- **Prometheus**
- **Prowlarr**
- **Qbittorrent**
- **Radarr**
- **Redbot**
- **Requestrr**
- **SABnzbd**
- **Sonarr**
- **Suwayomi**
- **Traefik**
- **Vector**
- **Wazuh**

## Contributing

If you would like to contribute to this repository, feel free to fork it, create a branch, and submit a pull request. Please follow the guidelines for setting up new Kubernetes resources and ensure that all changes are properly documented.

## License

This repository is licensed under the MIT License.
