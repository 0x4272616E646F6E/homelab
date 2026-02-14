output "schematic_id" {
  description = "Talos image factory schematic ID"
  value       = talos_image_factory_schematic.this.id
}

output "talosconfig" {
  description = "Talos client configuration"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes kubeconfig"
  value       = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}
