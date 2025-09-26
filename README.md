# Homelab

![Proxmox](https://img.shields.io/badge/Proxmox%209.0.10-proxmox?style=flat-square&logo=proxmox&logoColor=%23E57000&labelColor=%232b2a33&color=%232b2a33)
![Ansible](https://img.shields.io/badge/Ansible%202.18.8-%23EE0000.svg?style=flat-square&logo=ansible&logoColor=white)
![OpenTofu](https://img.shields.io/badge/OpenTofu%201.10.6-623CE4?style=flat-square&logo=opentofu&logoColor=white)
![Talos](https://img.shields.io/badge/Talos%20Linux%201.11.1-%23F36D00?style=flat-square&logo=talos&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes%201.34.1-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white)
![Nix](https://img.shields.io/badge/Nix%2025.05-5277C3?style=flat-square&logo=nixos&logoColor=white)

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux automatically applies changes from this repository to the Kubernetes cluster.

## Table of Contents

- [Prerequisites](#prerequisites)
- [General Cluster Architecture](#general-cluster-architecture)
- [Hardware Specs](#hardware-specs)
- [Cluster Resources](#cluster-resources)

## Prerequisites

Before using this repository, ensure you have:

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **CDK8s**: [Install CDK8s](https://cdk8s.io/docs/latest/cli/installation/)
- **CDKTF**: [Install CDKTF](https://developer.hashicorp.com/terraform/tutorials/cdktf/cdktf-install)
- **Cilium CLI**: [Install Cilium CLI](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli)
- **Flux CLI**: [Install Flux CLI](https://fluxcd.io/docs/installation/)
- **Git**: [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- **Kubectl**: [Install Kubectl](https://kubernetes.io/docs/tasks/tools/)
- **OpenTofu**: [Install OpenTofu](https://opentofu.org/docs/intro/install/)
- **SOPS**: [Install SOPS](https://getsops.io/docs/#download)
- **Talosctl**: [Install Talosctl](https://www.talos.dev/v1.10/talos-guides/install/talosctl/)

Or use nix.

- **Nix**: [Install Nix](https://github.com/DeterminateSystems/nix-installer)

## General Cluster Architecture

```mermaid
flowchart TD
  %% External
  subgraph External
    GIT[Git Repository]
    USER[Talosctl Client]
    LOCALNET[Local Ingress]
    NET[Internet Ingress]
  end

  %% Control Plane
  subgraph ControlPlane
    APIS[Kubernetes API Server]
    ETCD[(etcd)]
    SCHED[Scheduler]
    KCM[Kube Controller Manager]
  end

  APIS <--> ETCD
  SCHED --> APIS
  KCM --> APIS

  %% GitOps (runs in cluster)
  subgraph GitOps
    FLUX[Flux Controllers]
  end

  GIT <--> FLUX
  FLUX --> APIS

  %% Nodes / Data Plane
  subgraph Nodes
    KUBE[Kubelet]
    CRI[Containerd]
    CIL[Cilium]
    DNS[CoreDNS]
    TRF[HAProxy/Nginx/Traefik]
    CFD[Cloudflared]
  end

  KUBE <--> APIS
  CRI -. Runtime .-> KUBE
  CIL -. CNI .- KUBE
  DNS --> APIS
  TRF --> APIS
  CFD --> TRF
  NET --> CFD
  LOCALNET --> TRF
  CFD --> APIS
  CIL --> DNS
  CIL --> TRF


  %% Storage
  subgraph Storage
    LPP[Local-Path-Provisioner]
  end

  LPP --> APIS
  KUBE --> LPP

  %% Applications
  subgraph Applications
    APP[Application Pods]
  end

  APIS --> APP
  CIL --> APP
  TRF --> APP
  APP --> LPP

  %% Talos management
  USER --> KUBE
```

## Hardware Specs

Below is a description of the hardware this cluster runs on:

- Chassis: [SuperMicro SuperChassis 216](https://www.supermicro.com/en/products/chassis/2u/216/sc216be2c-r609jbod)
- PSU (2x): [SuperMicro 920W Platinum Super Quiet](https://store.supermicro.com/media/wysiwyg/productspecs/PWS-920P-SQ/PWS-920P-SQ_quick_spec.pdf)
- Motherboard: [Supermicro X13SAE-F](https://www.supermicro.com/en/products/motherboard/x13sae-f)
- CPU: [Intel i9 14900K](https://www.intel.com/content/www/us/en/products/sku/236773/intel-core-i9-processor-14900k-36m-cache-up-to-6-00-ghz/specifications.html)
- Memory (4x): [MEM-Store 48GB DDR5-4800MHz UDIMM ECC RAM](https://www.ebay.com/itm/205361780350?_skw=ddr5+x13sae&itmmeta=01JZ0TKE59VY4SVBFZCFZX65AM&hash=item2fd084167e:g:pYsAAOSwt3hoKGu2&itmprp=enc%3AAQAKAAAA8FkggFvd1GGDu0w3yXCmi1dRM0UvCMIXXuRtGvP1U0hYxySNWZ6v%2FH1IHx9NvHxTPBugsoKKGWAJZurMe47er848d9JodLXhjQJLTZllw0iFy0UeU7yOyJXFxEsQsbjQMukpohGX%2BupDrHUFRL2b9lanYMMNKdBWBvqApcgJV6mNUkd45LbWL91FksGhjB5BLBY0wP4Ad7nbqOfj8jNcHbMrsqnkS3miAhPWkoTubUR%2FIHgZK1ExaiV68B0Q5hLNQz1WssJtzBkAL%2BjfDvv1Ntg72LLsN6BdgOvJkT4JzFuBVsjT5gJzr9TFnTyNLTbuRg%3D%3D%7Ctkp%3ABk9SR87jzZr4ZQ)
- HBA: [LSI SAS 9300-8i](https://docs.broadcom.com/doc/12352000)
- OS Disks (2x): [Intel Optane SSD 1600X Series](https://www.intel.com/content/www/us/en/products/sku/211868/intel-optane-ssd-p1600x-series-58gb-m-2-80mm-pcie-3-0-x4-3d-xpoint/specifications.html)
- Data Disks (24x): [Samsung SAS PM1633_3840](https://download.semiconductor.samsung.com/resources/brochure/pm1633-prodoverview-2015.pdf)
- GPU: [NVIDIA RTX 4000 SFF Ada](https://www.nvidia.com/en-us/products/workstations/rtx-4000-sff/)
- TPU: [Google Coral TPU M.2 B+M](https://coral.ai/products/m2-accelerator-bm)

## Cluster Resources

The following resources are managed through Flux in this repository:

- [**Actions Runner Controller**](https://github.com/actions/actions-runner-controller)
- [**Authentik**](https://github.com/goauthentik/authentik)
- [**Bazarr**](https://github.com/morpheus65535/bazarr)
- [**BuildKit**](https://github.com/moby/buildkit)
- [**Cert Manager**](https://github.com/cert-manager/cert-manager)
- [**Cilium**](https://github.com/cilium/cilium)
- [**Cloudflared**](https://github.com/cloudflare/cloudflared)
- [**Code-Server**](https://github.com/coder/code-server)
- [**ComfyUI**](https://github.com/comfyanonymous/ComfyUI)
- [**Debian**](https://hub.docker.com/_/debian)
- [**Falco**](https://github.com/falcosecurity/falco)
- [**Filebrowser**](https://github.com/gtsteffaniak/filebrowser)
- [**Flaresolverr**](https://github.com/FlareSolverr/FlareSolverr)
- [**Glance**](https://github.com/glanceapp/glance)
- [**Grafana**](https://github.com/grafana/grafana)
- [**HAProxy**](https://github.com/jcmoraisjr/haproxy-ingress)
- [**Harbor**](https://github.com/goharbor/harbor)
- [**Home Assistant**](https://github.com/home-assistant/core)
- [**Huntarr**](https://github.com/plexguide/Huntarr.io)
- [**Jellyfin**](https://github.com/jellyfin/jellyfin)
- [**Jellyseerr**](https://github.com/fallenbagel/jellyseerr)
- [**Kestra**](https://github.com/kestra-io/kestra)
- [**Knative**](https://github.com/knative/serving)
- [**Kubelet CSR Approver**](https://github.com/postfinance/kubelet-csr-approver)
- [**Lazy Librarian**](https://gitlab.com/LazyLibrarian/LazyLibrarian)
- [**LibreChat**](https://github.com/danny-avila/LibreChat)
- [**Local Path Provisioner**](https://github.com/rancher/local-path-provisioner)
- [**Loki**](https://github.com/grafana/loki)
- [**Minecraft Server**](https://github.com/itzg/docker-minecraft-server)
- [**Nginx**](https://github.com/kubernetes/ingress-nginx)
- [**Nvidia Device Plugin**](https://github.com/NVIDIA/k8s-device-plugin)
- [**NzbGet**](https://github.com/nzbgetcom/nzbget)
- [**Prometheus**](https://github.com/prometheus/prometheus)
- [**Prowlarr**](https://github.com/Prowlarr/Prowlarr)
- [**Radarr**](https://github.com/Radarr/Radarr)
- [**Redbot**](https://github.com/Cog-Creators/Red-DiscordBot)
- [**Reflector**](https://github.com/emberstack/kubernetes-reflector)
- [**Requestrr**](https://github.com/thomst08/requestrr)
- [**Reloader**](https://github.com/stakater/Reloader)
- [**Renovate**](https://github.com/renovatebot/renovate)
- [**Sonarr**](https://github.com/Sonarr/Sonarr)
- [**SonarQube**](https://github.com/SonarSource/sonarqube)
- [**Subgen**](https://github.com/McCloudS/subgen)
- [**Suwayomi**](https://github.com/Suwayomi/Suwayomi-Server)
- [**Syncthing**](https://github.com/syncthing/syncthing)
- [**Tdarr**](https://github.com/HaveAGitGat/Tdarr)
- [**Tempo**](https://github.com/grafana/tempo)
- [**Traefik**](https://github.com/traefik/traefik)
- [**Vector**](https://github.com/vectordotdev/vector)
- [**Vertical Pod Autoscaler**](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [**VLLM**](https://github.com/vllm-project/vllm)
- [**Wizarr**](https://github.com/wizarrrr/wizarr)
