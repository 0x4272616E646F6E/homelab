terraform {
  required_version = ">= 1.10"

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9"
    }
  }
}
