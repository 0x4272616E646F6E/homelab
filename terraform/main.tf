# Cloudflare Config
module "cloudflare" {
  source = "./modules/cloudflare"

}

# Proxmox Config
module "proxmox" {
  source = "./modules/proxmox"

  depends_on = [module.unifi]
}

# Talos Config
module "talos" {
  source = "./modules/talos"

  depends_on = [module.proxmox]
}

# UniFi Config
module "unifi" {
  source = "./modules/unifi"

}
