variable "environment" {
  description = "Environment name"
  type        = string
  default     = ""
}

variable "wireguard_private_key" {
  description = "WireGuard private key for Talos Proton VPN tunnel"
  type        = string
  sensitive   = true
}
