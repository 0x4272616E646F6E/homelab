variable "cluster_name" {
  description = "Talos cluster name"
  type        = string
  default     = "talos"
}

variable "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  type        = string
  default     = "https://talos.hosted.fail:6443"
}

variable "node_ip" {
  description = "IP address of the Talos node"
  type        = string
  default     = "10.0.0.250"
}

variable "talos_version" {
  description = "Talos OS version"
  type        = string
  default     = "v1.12.2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.35.0"
}

variable "wireguard_private_key" {
  description = "WireGuard private key for Proton VPN tunnel"
  type        = string
  sensitive   = true
}
