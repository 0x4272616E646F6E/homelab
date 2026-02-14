# Cloudflare Config
module "cloudflare" {
  source = "./cloudflare"

}

# Proxmox Config
module "proxmox" {
  source = "./proxmox"
}

# Talos Config
module "talos" {
  source = "./talos"

  wireguard_private_key = var.wireguard_private_key

  depends_on = [module.proxmox]
}

