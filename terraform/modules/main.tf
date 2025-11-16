# Cloudflare Config
module "cloudflare" {
  source = "./cloudflare"

}

# Proxmox Config
module "proxmox" {
  source = "./proxmox"

  depends_on = [module.unifi]
}

# Talos Config
module "talos" {
  source = "./talos"

  depends_on = [module.proxmox]
}

# UniFi Config
module "unifi" {
  source = "./unifi"

}
