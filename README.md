![Proxmox](https://img.shields.io/badge/Proxmox-proxmox?style=flat-square&logo=proxmox&logoColor=%23E57000&labelColor=%232b2a33&color=%232b2a33)
![Ansible](https://img.shields.io/badge/Ansible-%23EE0000.svg?style=flat-square&logo=ansible&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-623CE4?style=flat-square&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white)

# Homelab

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux automatically applies changes from this repository to your Kubernetes cluster.

## Table of Contents

- [Prerequisites](#prerequisites)
- [General Cluster Architecture](#general-cluster-architecture)
- [Hardware Specs](#hardware-specs)
- [Resources Managed](#resources-managed)

## Prerequisites

Before using this repository, ensure you have:

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **CDK8s**: [Install CDK8s](https://cdk8s.io/docs/latest/cli/installation/)
- **CDKTF**: [Install CDKTF](https://developer.hashicorp.com/terraform/tutorials/cdktf/cdktf-install)
- **Cilium CLI**: [Install Cilium](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli)
- **Flux CLI**: [Install the Flux CLI](https://fluxcd.io/docs/installation/)
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
- PSU (2x): [SuperMicro 920W Platinum Super Quiet](https://store.supermicro.com/media/wysiwyg/productspecs/PWS-920P-SQ/PWS-920P-SQ_quick_spec.pdf)
- Motherboard: [Supermicro X13SAE-F](https://www.supermicro.com/en/products/motherboard/x13sae-f)
- CPU: [Intel i9 14900K](https://www.intel.com/content/www/us/en/products/sku/236773/intel-core-i9-processor-14900k-36m-cache-up-to-6-00-ghz/specifications.html)
- Memory (4x): [MEM-Store 48GB DDR5-4800MHz UDIMM ECC RAM](https://www.ebay.com/itm/205361780350?_skw=ddr5+x13sae&itmmeta=01JZ0TKE59VY4SVBFZCFZX65AM&hash=item2fd084167e:g:pYsAAOSwt3hoKGu2&itmprp=enc%3AAQAKAAAA8FkggFvd1GGDu0w3yXCmi1dRM0UvCMIXXuRtGvP1U0hYxySNWZ6v%2FH1IHx9NvHxTPBugsoKKGWAJZurMe47er848d9JodLXhjQJLTZllw0iFy0UeU7yOyJXFxEsQsbjQMukpohGX%2BupDrHUFRL2b9lanYMMNKdBWBvqApcgJV6mNUkd45LbWL91FksGhjB5BLBY0wP4Ad7nbqOfj8jNcHbMrsqnkS3miAhPWkoTubUR%2FIHgZK1ExaiV68B0Q5hLNQz1WssJtzBkAL%2BjfDvv1Ntg72LLsN6BdgOvJkT4JzFuBVsjT5gJzr9TFnTyNLTbuRg%3D%3D%7Ctkp%3ABk9SR87jzZr4ZQ)
- HBA: [LSI SAS 9300-8i](https://docs.broadcom.com/doc/12352000)
- OS Disks (2x): [Intel Optane SSD 1600X Series](https://www.intel.com/content/www/us/en/products/sku/211868/intel-optane-ssd-p1600x-series-58gb-m-2-80mm-pcie-3-0-x4-3d-xpoint/specifications.html)
- Data Disks (24x): [Samsung SAS PM1633_3840](https://download.semiconductor.samsung.com/resources/brochure/pm1633-prodoverview-2015.pdf)
- GPU: [NVIDIA RTX 4000 SFF Ada](https://www.nvidia.com/en-us/products/workstations/rtx-4000-sff/)
- TPU: [Google Coral TPU M.2](https://coral.ai/products/m2-accelerator-bm)

## Cluster Resources

The following resources are managed through Flux in this repository:

- **Actions Runner Controller**
- **Alpine (Talos Debug)**
- **Authentik**
- **Bazarr**
- **BuildKit**
- **Cert Manager**
- **Cilium**
- **Cloudflared**
- **Code-Server**
- **Comfy-UI**
- **Egress Gateway Helper**
- **Emissary**
- **Falco**
- **Filebrowser**
- **Flaresolverr**
- **Glance**
- **Grafana**
- **HA Proxy**
- **Harbor**
- **Home Assistant**
- **Huntarr**
- **Jellyfin**
- **Jellyseerr**
- **KEDA**
- **Kestra**
- **Kubelet CSR Approver**
- **Loki**
- **Minecraft Server**
- **Nvidia Device Plugin**
- **NzbGet**
- **Prometheus**
- **Prowlarr**
- **Radarr**
- **Redbot**
- **Reflector**
- **Requestrr**
- **Reloader**
- **Renovate**
- **Rook**
- **rTorrent**
- **Sonarr**
- **SonarQube**
- **Subgen**
- **Suwayomi**
- **Syncthing**
- **Tdarr**
- **Tempo**
- **Traefik**
- **Vector**
- **Vertical Pod Autoscaler**
- **VLLM**
- **Wizarr**

