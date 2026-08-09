output "schematic_id" {
  description = "Talos image factory schematic ID"
  value       = module.talos.schematic_id
}

output "talosconfig" {
  description = "Talos client configuration"
  value       = module.talos.talosconfig
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes kubeconfig"
  value       = module.talos.kubeconfig
  sensitive   = true
}
