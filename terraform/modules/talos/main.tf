resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/gasket-driver",
          "siderolabs/i915",
          "siderolabs/nonfree-kmod-nvidia-production",
          "siderolabs/nvidia-container-toolkit-production",
          "siderolabs/qemu-guest-agent",
          "siderolabs/util-linux-tools",
          "siderolabs/youki",
        ]
      }
    }
  })
}

# Machine secrets
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

# Apply machine configuration
resource "talos_machine_configuration_apply" "this" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  node                        = var.node_ip
  endpoint                    = var.node_ip

  config_patches = [
    local.machine_patch,
    local.cluster_patch,
  ]
}

# Bootstrap
resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.node_ip
  endpoint             = var.node_ip
}
