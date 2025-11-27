resource "unifi_site" "homelab" {
  description = "homelab"
}

resource "unifi_setting_mgmt" "homelab_settings" {
  site         = unifi_site.homelab.name
  auto_upgrade = true
}
