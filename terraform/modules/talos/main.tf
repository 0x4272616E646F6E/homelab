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

  lifecycle {
    # Losing these makes the cluster unmanageable
    prevent_destroy = true
  }
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

  timeouts {
    create = "10m"
    update = "10m"
  }
}

# Bootstrap
resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.node_ip
  endpoint             = var.node_ip
}

# Drift tripwire -- see docs/NOTES.md for the full drift table.
# terraform_data is built in, so this adds no provider dependency.
resource "terraform_data" "drift_guard" {
  input = "see docs/NOTES.md"

  lifecycle {
    precondition {
      condition     = var.allow_apply_despite_drift
      error_message = <<-EOT
        terraform/modules/talos is out of sync with the live node and cannot produce a
        bootable control plane as written. Reconcile it against
        /zfs/pve/snippets/controlplane.yaml first, then set
        allow_apply_despite_drift = true. See docs/NOTES.md for the drift table.
      EOT
    }
  }
}
