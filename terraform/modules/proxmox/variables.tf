variable "environment" {
  description = "Environment name"
  type        = string
  default     = ""
}

variable "talos_vmid" {
  description = "Proxmox VM ID for the Talos control-plane VM"
  type        = number
  default     = 2250
}

variable "talos_macaddr" {
  description = "MAC address for the Talos VM primary NIC"
  type        = string
  default     = "BC:24:11:61:5B:80"
}

variable "pbs_vmid" {
  description = "Proxmox VM ID for the Proxmox Backup Server VM"
  type        = number
  default     = 2251
}

variable "pbs_macaddr" {
  description = "MAC address for the PBS VM primary NIC"
  type        = string
  default     = "BC:24:11:47:DD:28"
}
