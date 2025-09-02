![Intel](https://img.shields.io/badge/intel-%230068B5%20.svg?style=for-the-badge&logo=intel&logoColor=white)
![nVIDIA](https://img.shields.io/badge/nVIDIA-%2376B900.svg?style=for-the-badge&logo=nVIDIA&logoColor=white)
![Proxmox](https://img.shields.io/badge/proxmox-proxmox?style=for-the-badge&logo=proxmox&logoColor=%23E57000&labelColor=%232b2a33&color=%232b2a33)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Java](https://img.shields.io/badge/Java-2b2a33?style=for-the-badge&logo=openjdk&logoColor=F80000)

# Homelab

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux automatically applies changes from this repository to your Kubernetes cluster.

## Table of Contents

- [Prerequisites](#prerequisites)
- [CDK8s](#cdk8s)
- [Flux Setup](#flux-setup)
- [General Cluster Architecture](#general-cluster-architecture)
- [Hardware Specs](#hardware-specs)
- [Resources Managed](#resources-managed)
- [Runtimes](#runtimes)

## Prerequisites

Before using this repository, ensure you have:

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **CDK8s**: [Install CDK8s](https://cdk8s.io/docs/latest/cli/installation/)
- **Cilium CLI**: [Install Cilium](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli)
- **Flux CLI**: [Install the Flux CLI](https://fluxcd.io/docs/installation/)
- **Git**: [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- **Kubectl**: [Install Kubectl](https://kubernetes.io/docs/tasks/tools/)
- **Talosctl**: [Install Talosctl](https://www.talos.dev/v1.10/talos-guides/install/talosctl/)

## CDK8s

CDK8s (Cloud Development Kit for Kubernetes) allows defining Kubernetes manifests using familiar programming languages instead of YAML.

This repo uses **Java** with CDK8s to generate Kubernetes manifests that are then managed by Flux.

**Workflow:**
1. Write Kubernetes applications in Java using CDK8s constructs
2. Run `cdk8s synth` to generate standard Kubernetes YAML manifests
3. Commit generated manifests to this repository
4. Flux automatically applies changes to the cluster

## Flux Setup

Flux manages the deployment of Kubernetes resources in this repository. Key resources:

- **GitRepository**: Specifies the Git repository, branch, and sync interval for Flux.
- **HelmRepository**: Specifies the helm repository, type, and interval for Flux.
- **Kustomization**: Defines which paths and resources Flux applies to the cluster.

## General Cluster Architecture

```mermaid
flowchart TD
    subgraph GitOps
        G1[Git Repository]
        G2[Flux]
        G1 --> G2
    end

    subgraph ControlPlane
        G2 --> C1[Kubernetes API Server]
        C1 --> C2[Controllers & CRDs]
        C1 --> C3[(etcd)]
        C1 --> C4[Kube Scheduler]
        C1 --> C5[Kube Controller]
        C2 --> C6[Talos Debug]
    end


    subgraph DataPlane
        C2 --> D1[Cilium]
        C2 --> D2[CoreDNS]
        %% Node-level components
        D3[Kubelet] -.-> D1
        C1 -.-> D3[Kubelet]
        D4[containerd] -.-> D3
    end


    subgraph Ingress
        direction TB
        C2 --> I1[Cloudflared]
        C2 --> I2[Emissary/HaProxy/Traefik]
        D1 --> I1[Cloudflared]
        D1 --> I2[Emissary/HaProxy/Traefik]
    end

    subgraph Applications
        direction TB
        C2 --> A1[App]
         I1 --> A1[App]
         I2 --> A1[App]
    end

    subgraph Storage
        direction TB
        C2 --> S1[Rook]
        A1 --> S1[Rook]
    end

```

## Hardware Specs

Below is a description of the hardware this cluster runs on. This information may be useful if you want to build a similar setup or understand resource utilization in relation to this deployment.

- Chassis: [SuperMicro SuperChassis 216](https://www.supermicro.com/en/products/chassis/2u/216/sc216be2c-r609jbod)
- PSU (2x): [SuperMicro 920W Platinum Super Quiet](https://store.supermicro.com/920w-1u-pws-920p-sq.html)
- Motherboard: [Supermicro X13SAE-F](https://www.supermicro.com/en/products/motherboard/x13sae-f)
- CPU: [Intel i9 14900K](https://www.intel.com/content/www/us/en/products/sku/236773/intel-core-i9-processor-14900k-36m-cache-up-to-6-00-ghz/specifications.html)
- Memory (4x): [MEM-Store 48GB DDR5-4800MHz UDIMM ECC RAM](https://www.ebay.com/itm/205361780350?_skw=ddr5+x13sae&itmmeta=01JZ0TKE59VY4SVBFZCFZX65AM&hash=item2fd084167e:g:pYsAAOSwt3hoKGu2&itmprp=enc%3AAQAKAAAA8FkggFvd1GGDu0w3yXCmi1dRM0UvCMIXXuRtGvP1U0hYxySNWZ6v%2FH1IHx9NvHxTPBugsoKKGWAJZurMe47er848d9JodLXhjQJLTZllw0iFy0UeU7yOyJXFxEsQsbjQMukpohGX%2BupDrHUFRL2b9lanYMMNKdBWBvqApcgJV6mNUkd45LbWL91FksGhjB5BLBY0wP4Ad7nbqOfj8jNcHbMrsqnkS3miAhPWkoTubUR%2FIHgZK1ExaiV68B0Q5hLNQz1WssJtzBkAL%2BjfDvv1Ntg72LLsN6BdgOvJkT4JzFuBVsjT5gJzr9TFnTyNLTbuRg%3D%3D%7Ctkp%3ABk9SR87jzZr4ZQ)
- HBA: [LSI SAS 9300-8i](https://docs.broadcom.com/doc/12352000)
- OS Disks (2x): [Intel Optane SSD 1600X Series](https://www.intel.com/content/www/us/en/products/sku/211868/intel-optane-ssd-p1600x-series-58gb-m-2-80mm-pcie-3-0-x4-3d-xpoint/specifications.html)
- Data Disks (24x): [Samsung SAS PM1633_3840](https://download.semiconductor.samsung.com/resources/brochure/pm1633-prodoverview-2015.pdf)
- GPU: [NVIDIA RTX 4000 SFF Ada](https://www.nvidia.com/en-us/products/workstations/rtx-4000-sff/)
- TPU: [Google Coral TPU M.2](https://coral.ai/products/m2-accelerator-bm)

## Resources Managed

The following resources are managed through Flux in this repository:

- [x] **Actions Runner Controller**
- [X] **Authentik**
- [x] **Bazarr**
- [x] **BuildKit**
- [x] **Cert Manager**
- [x] **Cilium**
- [X] **Cloudflared**
- [x] **Coder**
- [x] **Comfy-UI**
- [x] **Egress Gateway Helper**
- [x] **Emissary**
- [x] **Falco**
- [x] **Filebrowser**
- [x] **Flaresolverr**
- [x] **Gamevault**
- [x] **Glance**
- [x] **Grafana**
- [x] **HA Proxy**
- [X] **Harbor**
- [x] **Home Assistant**
- [x] **Huntarr**
- [x] **Jellyfin**
- [x] **Jellyseerr**
- [ ] **KEDA**
- [ ] **Kestra**
- [x] **Kubelet CSR Approver**
- [x] **Loki**
- [x] **Minecraft Server**
- [x] **Nix2Container**
- [x] **Nvidia Device Plugin**
- [x] **NzbGet**
- [x] **Prometheus**
- [x] **Prowlarr**
- [x] **Radarr**
- [x] **Redbot**
- [x] **Reflector**
- [x] **Requestrr**
- [x] **Renovate**
- [x] **Rook**
- [x] **rTorrent**
- [x] **Sonarr**
- [x] **SonarQube**
- [x] **Subgen**
- [x] **Suwayomi**
- [x] **Syncthing**
- [x] **Talos Debug**
- [x] **Tdarr**
- [x] **Tempo**
- [x] **Traefik**
- [x] **Vector**
- [x] **VLLM**
- [x] **Wizarr**

## Runtimes

These are the runtimes used in this cluster:

- **Container Runtimes**
  - **Default**: `runc`
  - **Alternative** `youki`
  - **GPU** `nvidia`
