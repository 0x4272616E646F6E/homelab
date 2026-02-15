locals {
  machine_patch = yamlencode({
    machine = {
      network = {
        hostname = "talos-4m3-8nj"
        interfaces = [
          {
            interface = "eth0"
            addresses = ["${var.node_ip}/24"]
            routes = [
              {
                network = "0.0.0.0/0"
                gateway = "10.0.0.1"
                metric  = 100
              }
            ]
          },
          {
            interface = "wg0"
            addresses = ["10.2.0.2/32"]
            wireguard = {
              privateKey = var.wireguard_private_key
              peers = [
                {
                  publicKey                 = "HPBiH3IvPfISyPb+pw5BiSi7I7ZF1I4/UfzEQWbeZFk="
                  endpoint                  = "89.222.96.129:51820"
                  allowedIPs                = ["0.0.0.0/0", "::/0"]
                  persistentKeepaliveInterval = "10s"
                }
              ]
            }
          }
        ]
      }

      kubelet = {
        image                                = "ghcr.io/siderolabs/kubelet:${var.kubernetes_version}"
        defaultRuntimeSeccompProfileEnabled = true
        disableManifestsDirectory           = true
        extraArgs = {
          "node-ip"                 = var.node_ip
          address                   = "0.0.0.0"
          "max-pods"                = "250"
          "event-qps"              = "0"
          "registry-qps"           = "0"
          "pods-per-core"          = "0"
          "serialize-image-pulls"  = "true"
          "registry-burst"         = "5"
          "container-log-max-size" = "10Mi"
          "container-log-max-files" = "3"
          "kube-api-qps"           = "50"
          "kube-api-burst"         = "100"
        }
        extraMounts = [
          {
            destination = "/dev/dri"
            type        = "bind"
            source      = "/dev/dri"
            options     = ["bind", "rshared", "rw"]
          },
          {
            destination = "/var/lib/kubelet/device-plugins"
            type        = "bind"
            source      = "/var/lib/kubelet/device-plugins"
            options     = ["rbind", "rshared", "rw"]
          }
        ]
        extraConfig = {
          featureGates = {
            UserNamespacesSupport = true
          }
          systemReserved = {
            cpu                 = "1000m"
            memory              = "2Gi"
            "ephemeral-storage" = "10Gi"
          }
          kubeReserved = {
            cpu                 = "1000m"
            memory              = "2Gi"
            "ephemeral-storage" = "5Gi"
          }
          evictionHard = {
            "memory.available" = "500Mi"
            "nodefs.available" = "10%"
          }
          imageGCHighThresholdPercent = 70
          imageGCLowThresholdPercent  = 50
          imageMinimumGCAge           = "2m0s"
        }
      }

      features = {
        rbac                 = true
        stableHostname       = true
        apidCheckExtKeyUsage = true
        diskQuotaSupport     = true
        kubePrism = {
          enabled = true
          port    = 7445
        }
        hostDNS = {
          enabled              = true
          forwardKubeDNSToHost = true
        }
      }

      nodeLabels = {
        "node.kubernetes.io/exclude-from-external-load-balancers" = ""
      }

      install = {
        disk  = "/dev/sda"
        image = "factory.talos.dev/installer/${talos_image_factory_schematic.this.id}:${var.talos_version}"
      }

      disks = [
        {
          device = "/dev/sdb"
          partitions = [
            { mountpoint = "/var/mnt/storage" }
          ]
        }
      ]

      kernel = {
        modules = [
          { name = "apex" },
          { name = "br_netfilter", parameters = ["nf_conntrack_max=131072"] },
          { name = "nf_conntrack" },
          { name = "nf_nat" },
          { name = "xt_conntrack" },
          { name = "dm_mod" },
          { name = "drm" },
          { name = "gasket" },
          { name = "nbd" },
          { name = "nvidia" },
          { name = "nvidia_uvm" },
          { name = "nvidia_drm" },
          { name = "nvidia_modeset" },
          { name = "tun" },
          { name = "uio_pci_generic" },
          { name = "vfio_pci" },
        ]
      }

      sysctls = {
        "fs.inotify.max_user_instances"    = "8192"
        "net.core.bpf_jit_harden"         = "1"
        "net.core.rmem_max"               = "2500000"
        "net.core.somaxconn"              = "65535"
        "net.core.wmem_max"               = "16777216"
        "net.ipv4.conf.all.arp_announce"  = "2"
        "net.ipv4.conf.all.arp_ignore"    = "0"
        "net.ipv4.conf.all.arp_notify"    = "1"
        "net.ipv4.conf.all.forwarding"    = "1"
        "net.ipv4.conf.default.arp_ignore"   = "0"
        "net.ipv4.conf.default.arp_announce" = "2"
        "net.ipv4.conf.eth0.arp_ignore"   = "0"
        "net.ipv4.conf.eth0.arp_announce" = "2"
        "net.ipv4.conf.wg0.rp_filter"    = "2"
        "net.ipv4.tcp_fin_timeout"        = "15"
        "net.ipv4.tcp_keepalive_time"     = "30"
        "net.ipv4.tcp_keepalive_intvl"    = "10"
        "net.ipv4.tcp_keepalive_probes"   = "6"
        "net.ipv4.tcp_rmem"              = "4096 87380 16777216"
        "net.ipv4.tcp_tw_reuse"          = "1"
        "net.ipv4.tcp_wmem"              = "4096 65536 16777216"
        "user.max_user_namespaces"        = "11255"
        "vm.max_map_count"               = "262144"
        "vm.nr_hugepages"                = "1024"
      }

      sysfs = {
        "block.sda.queue.scheduler" = "mq-deadline"
        "block.sdb.queue.scheduler" = "mq-deadline"
      }

      time = {
        disabled = false
        servers  = ["time.cloudflare.com"]
      }

      registries = {
        mirrors = {
          "ghcr.io" = {
            endpoints = ["https://ghcr.io"]
          }
        }
      }
    }
  })

  cluster_patch = yamlencode({
    cluster = {
      apiServer = {
        image    = "registry.k8s.io/kube-apiserver:${var.kubernetes_version}"
        certSANs = [var.node_ip, "127.0.0.1"]
        disablePodSecurityPolicy = true
        admissionControl = [
          {
            name = "PodSecurity"
            configuration = {
              apiVersion = "pod-security.admission.config.k8s.io/v1"
              kind       = "PodSecurityConfiguration"
              defaults = {
                audit              = "restricted"
                "audit-version"    = "latest"
                enforce            = "baseline"
                "enforce-version"  = "latest"
                warn               = "restricted"
                "warn-version"     = "latest"
              }
              exemptions = {
                namespaces     = ["kube-system"]
                runtimeClasses = []
                usernames      = []
              }
            }
          }
        ]
        auditPolicy = {
          apiVersion = "audit.k8s.io/v1"
          kind       = "Policy"
          rules      = [{ level = "Metadata" }]
        }
        extraArgs = {
          "default-not-ready-toleration-seconds"   = "300"
          "default-unreachable-toleration-seconds"  = "300"
          "feature-gates"                           = "UserNamespacesSupport=true"
          "max-requests-inflight"                   = "100"
          "max-mutating-requests-inflight"          = "50"
          "watch-cache-sizes"                       = "events#100,pods#1000"
        }
      }

      controllerManager = {
        image = "registry.k8s.io/kube-controller-manager:${var.kubernetes_version}"
        extraArgs = {
          "kube-api-qps"                 = "50"
          "kube-api-burst"               = "80"
          "concurrent-deployment-syncs"  = "3"
          "concurrent-replicaset-syncs"  = "3"
          "concurrent-statefulset-syncs" = "3"
        }
      }

      proxy = {
        disabled = true
      }

      scheduler = {
        image = "registry.k8s.io/kube-scheduler:${var.kubernetes_version}"
        extraArgs = {
          "kube-api-qps"   = "50"
          "kube-api-burst" = "100"
        }
      }

      discovery = {
        enabled = true
        registries = {
          kubernetes = { disabled = true }
          service    = {}
        }
      }

      etcd = {
        extraArgs = {
          "listen-metrics-urls"       = "http://0.0.0.0:2381"
          "heartbeat-interval"        = "1000"
          "election-timeout"          = "40000"
          "quota-backend-bytes"       = "8589934592"
          "max-request-bytes"         = "10485760"
          "auto-compaction-mode"      = "periodic"
          "auto-compaction-retention" = "1h"
          "backend-batch-interval"    = "100ms"
          "backend-batch-limit"       = "10000"
          "log-level"                 = "warn"
        }
      }

      network = {
        dnsDomain = "cluster.local"
        podSubnets     = ["10.244.0.0/16"]
        serviceSubnets = ["10.96.0.0/12"]
        cni = { name = "none" }
      }

      allowSchedulingOnControlPlanes = true
    }
  })
}
