# Homelab

![Proxmox](https://img.shields.io/badge/Proxmox%20-proxmox?style=flat-square&logo=proxmox&logoColor=%23E57000&labelColor=%232b2a33&color=%232b2a33)
![Ansible](https://img.shields.io/badge/Ansible%20-%23EE0000.svg?style=flat-square&logo=ansible&logoColor=white)
![OpenTofu](https://img.shields.io/badge/OpenTofu%20-623CE4?style=flat-square&logo=opentofu&logoColor=white)
![Talos](https://img.shields.io/badge/Talos%20Linux%20-%23F36D00?style=flat-square&logo=talos&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes%20-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white)
![Flux](https://img.shields.io/badge/Flux%20-2168DE.svg?style=flat-square&logo=flux&logoColor=white)
![Nix](https://img.shields.io/badge/Nix%20-5277C3?style=flat-square&logo=nixos&logoColor=white)

This repository contains Kubernetes manifests for deploying and managing resources using **Flux** in a GitOps workflow. Flux automatically applies changes from this repository to the Kubernetes cluster.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Diagram](#diagram)
- [Hardware](#hardware)
- [Applications](#applications)

## Prerequisites

Before using this repository, ensure you have the following:

<details>
  <summary><b>Click here to view Prerequisites</b></summary>

- **Kubernetes Cluster**: A working Kubernetes cluster.
- **Cilium CLI**: [Install Cilium CLI](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli)
- **Flux CLI**: [Install Flux CLI](https://fluxcd.io/docs/installation/)
- **Git**: [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- **Kubectl**: [Install Kubectl](https://kubernetes.io/docs/tasks/tools/)
- **OpenTofu**: [Install OpenTofu](https://opentofu.org/docs/intro/install/)
- **SOPS**: [Install SOPS](https://getsops.io/docs/#download)
- **Talosctl**: [Install Talosctl](https://www.talos.dev/v1.10/talos-guides/install/talosctl/)
- **Terragrunt**: [Install Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)

Or use nix.

- **Nix**: [Install Nix](https://github.com/DeterminateSystems/nix-installer)
</details>

## Diagram

This diagram is a general cluster architecture diagram for this single node deployment:

<details>
  <summary><b>Click here to view Diagram</b></summary>

```mermaid
flowchart RL
  %% External
  subgraph External
    GIT[Git Repository]
    USER[Talosctl Client]
    LOCALNET[LAN]
    NET[WAN]
  end

  %% Node
  subgraph Node
    subgraph ControlPlane
      APIS[Kubernetes API]
      ETCD[(etcd)]
      SCHED[Kube Scheduler]
      KCM[Kube Controller]
    end
    
    KUBE[Kubelet]
    CRI[Containerd]
    CIL[Cilium]
    DNS[CoreDNS]
    NGX[NGINX]
    CFD[Cloudflared]
    WRG[WireGuard]
    LPP[Local-Path-Provisioner]
    APP[Application Pods]
    
    subgraph GitOps
      FLUX[Flux Controllers]
      REN[Renovate Bot]
    end
  end

  APIS <--> ETCD
  SCHED --> APIS
  KCM --> APIS

  GIT <-. Sync .-> FLUX
  REN -. Update .-> GIT
  FLUX --> APIS

  KUBE <--> APIS
  CRI -. Runtime .- KUBE
  CIL -. CNI .- KUBE
  DNS --> APIS
  APIS --> NGX
  CFD -. Reverse<br>Proxy<br>Chain .-> NGX
  NET -. WAN<br>Ingress .-> CFD
  LOCALNET -. LAN<br>Ingress .-> NGX
  CIL --> DNS
  CIL --> NGX
  WRG -. WAN<br>Egress .-> NET
  LPP --> APIS
  KUBE --> LPP
  APIS --> APP
  CIL -. mTLS .-> APP
  NGX -. Reverse<br>Proxy .-> APP
  APP -. Storage .-> LPP
  APP -. LAN<br>Egress .-> LOCALNET
  APP -. WAN<br>Egress .-> NET
  APP --> WRG

  %% Talos management
  USER --> KUBE
  
  %% Styling
  style External fill:#ff9800,stroke:#333,stroke-width:2px
  style ControlPlane fill:#64b5f6,stroke:#333,stroke-width:2px
  style GitOps fill:#81c784,stroke:#333,stroke-width:2px
```
</details>

## Hardware

Information regarding the hardware this homelab runs on:

<details>
  <summary><b>Click here to view Hardware</b></summary>

<img src="./docs/server_rack.jpg" alt="Homelab Rack" width="300"/>
<img src="./docs/server_internals.jpg" alt="Server Internals" width="300"/>

- [12u StarTech Rack](https://www.startech.com/en-us/server-management/4postrack12u)
- [UniFi Dream Machine Pro](https://store.ui.com/us/en/category/all-cloud-gateways/products/udm-pro)
- [UniFi Enterprise 24 PoE](https://store.ui.com/us/en/products/usw-enterprise-24-poe)
- [Unifi UNAS PRO 8](https://store.ui.com/us/en/category/all-integrations/products/unas-pro-8)
  - Disks (8x): [Seagate Exos 24TB ST24000NM000C](https://www.seagate.com/products/enterprise-drives/exos-x/x24/)
- Basic Patch Panel
- Supermicro Server
  - Chassis: [SuperMicro SuperChassis 216](https://www.supermicro.com/en/products/chassis/2u/216/sc216be2c-r609jbod)
  - PSU (2x): [SuperMicro 920W Platinum Super Quiet](https://store.supermicro.com/media/wysiwyg/productspecs/PWS-920P-SQ/PWS-920P-SQ_quick_spec.pdf)
  - Motherboard: [Supermicro X13SAE-F](https://www.supermicro.com/en/products/motherboard/x13sae-f)
  - CPU: [Intel i9 14900K](https://www.intel.com/content/www/us/en/products/sku/236773/intel-core-i9-processor-14900k-36m-cache-up-to-6-00-ghz/specifications.html)
  - Memory (4x): [MEM-Store 48GB DDR5-4800MHz UDIMM ECC RAM](https://www.ebay.com/itm/205361780350?_skw=ddr5+x13sae&itmmeta=01JZ0TKE59VY4SVBFZCFZX65AM&hash=item2fd084167e:g:pYsAAOSwt3hoKGu2&itmprp=enc%3AAQAKAAAA8FkggFvd1GGDu0w3yXCmi1dRM0UvCMIXXuRtGvP1U0hYxySNWZ6v%2FH1IHx9NvHxTPBugsoKKGWAJZurMe47er848d9JodLXhjQJLTZllw0iFy0UeU7yOyJXFxEsQsbjQMukpohGX%2BupDrHUFRL2b9lanYMMNKdBWBvqApcgJV6mNUkd45LbWL91FksGhjB5BLBY0wP4Ad7nbqOfj8jNcHbMrsqnkS3miAhPWkoTubUR%2FIHgZK1ExaiV68B0Q5hLNQz1WssJtzBkAL%2BjfDvv1Ntg72LLsN6BdgOvJkT4JzFuBVsjT5gJzr9TFnTyNLTbuRg%3D%3D%7Ctkp%3ABk9SR87jzZr4ZQ)
  - HBA: [Lenovo 430-16i](https://lenovopress.lenovo.com/lp0649-thinksystem-430-8i-16i-internal-sas-hba)
  - OS Disks (2x): [Intel Optane SSD 1600X Series](https://www.intel.com/content/www/us/en/products/sku/211868/intel-optane-ssd-p1600x-series-58gb-m-2-80mm-pcie-3-0-x4-3d-xpoint/specifications.html)
  - Data Disks (24x): [Samsung SAS PM1633_3840](https://download.semiconductor.samsung.com/resources/brochure/pm1633-prodoverview-2015.pdf)
  - NIC: [Intel X710-DA2](https://www.intel.com/content/www/us/en/products/sku/83964/intel-ethernet-converged-network-adapter-x710da2/specifications.html)
  - GPU 1: [NVIDIA RTX 4000 SFF Ada](https://www.nvidia.com/en-us/products/workstations/rtx-4000-sff/)
  - GPU 2:  [Intel Arc A310](https://www.sparkle.com.tw/en/products/view/f22F9bC73c50)
  - TPU: [Google Coral TPU M.2 B+M](https://coral.ai/products/m2-accelerator-bm)
- [CyberPower UPS](https://www.cyberpowersystems.com/product/ups/pfc-sinewave/cp1500pfcrm2u/)
</details>

## Applications

The following applications are managed through flux in this repository:

<details>
  <summary><b>Click here to view Applications</b></summary>

- [**Actions Runner Controller**](https://github.com/actions/actions-runner-controller)
- [**Anubis**](https://github.com/TecharoHQ/anubis)
- [**Bazarr**](https://github.com/morpheus65535/bazarr)
- [**BuildKit**](https://github.com/moby/buildkit)
- [**Cert Manager**](https://github.com/cert-manager/cert-manager)
- [**Cilium**](https://github.com/cilium/cilium)
- [**ClamAV**](https://www.clamav.net/)
- [**ClickStack**](https://clickhouse.com/docs/use-cases/observability/clickstack)
- [**Cloudflared**](https://github.com/cloudflare/cloudflared)
- [**Code-Server**](https://github.com/coder/code-server)
- [**Debian**](https://hub.docker.com/_/debian)
- [**Falco**](https://github.com/falcosecurity/falco)
- [**Flaresolverr**](https://github.com/FlareSolverr/FlareSolverr)
- [**Forgejo**](https://codeberg.org/forgejo/forgejo)
- [**Glance**](https://github.com/glanceapp/glance)
- [**Home Assistant**](https://github.com/home-assistant/core)
- [**Huntarr**](https://github.com/plexguide/Huntarr.io)
- [**Intel GPU Plugin**](https://github.com/intel/intel-device-plugins-for-kubernetes)
- [**Jellyfin**](https://github.com/jellyfin/jellyfin)
- [**Kubelet CSR Approver**](https://github.com/postfinance/kubelet-csr-approver)
- [**LlamaCPP**](https://github.com/ggml-org/llama.cpp)
- [**Local Path Provisioner**](https://github.com/rancher/local-path-provisioner)
- [**LocalStack**](https://github.com/localstack/localstack)
- [**Loki**](https://github.com/grafana/loki)
- [**NGINX Gateway Fabric**](https://github.com/nginx/nginx-gateway-fabric/tree/main)
- [**Nvidia Device Plugin**](https://github.com/NVIDIA/k8s-device-plugin)
- [**Open WebUI**](https://github.com/open-webui/open-webui)
- [**NzbGet**](https://github.com/nzbgetcom/nzbget)
- [**Prowlarr**](https://github.com/Prowlarr/Prowlarr)
- [**Qodo-PR-Agent**](https://github.com/qodo-ai/pr-agent)
- [**Radarr**](https://github.com/Radarr/Radarr)
- [**Redbot**](https://github.com/Cog-Creators/Red-DiscordBot)
- [**Reflector**](https://github.com/emberstack/kubernetes-reflector)
- [**Requestrr**](https://github.com/thomst08/requestrr)
- [**Reloader**](https://github.com/stakater/Reloader)
- [**Renovate**](https://github.com/renovatebot/renovate)
- [**Seerr**](https://github.com/seerr-team/seerr)
- [**Shelfmark**](https://github.com/calibrain/shelfmark)
- [**Snowflake**](https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake/-/tree/main/proxy?ref_type=heads#running-a-standalone-snowflake-proxy)
- [**Sonarr**](https://github.com/Sonarr/Sonarr)
- [**SonarQube**](https://github.com/SonarSource/sonarqube)
- [**Steam-Headless**](https://github.com/Steam-Headless/docker-steam-headless)
- [**Suwayomi**](https://github.com/Suwayomi/Suwayomi-Server)
- [**Tdarr**](https://github.com/HaveAGitGat/Tdarr)
- [**TinyAuth**](https://github.com/steveiliop56/tinyauth)
- [**Vertical Pod Autoscaler**](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [**Wizarr**](https://github.com/wizarrrr/wizarr)
</details>

## Star History

<div align="center">

<a href="https://www.star-history.com/embed?secret=#0x4272616E646F6E/homelab&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=0x4272616E646F6E/homelab&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=0x4272616E646F6E/homelab&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=0x4272616E646F6E/homelab&type=Date" />
  </picture>
</a>

</div>
