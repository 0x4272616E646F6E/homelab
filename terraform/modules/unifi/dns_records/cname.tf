locals {
  cname_hosts  = toset(["authentik",
                        "bazarr",
                        "comfyui",
                        "falco",
                        "flaresolverr",
                        "glance",
                        "grafana",
                        "harbor",
                        "homeassistant",
                        "huntarr",
                        "ersatztv",
                        "jellyfin",
                        "jellyseerr",
                        "librechat",
                        "minecraft",
                        "nzbget",
                        "prometheus",
                        "prowlarr",
                        "qbittorrent",
                        "radarr",
                        "requestrr",
                        "sonarqube",
                        "sonarr",
                        "suwayomi",
                        "syslog",
                        "tdarr",
                        "vscode",
                        "wizarr"])
  cname_domain = "hosted.fail"
  target_fqdn  = "traefik.hosted.fail"
}

resource "unifi_dns_record" "traefik_cname" {
  for_each = local.cname_hosts

  name        = "${each.key}.${local.cname_domain}"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "CNAME"
  ttl         = 300
  value       = local.traefik_target_fqdn
}
