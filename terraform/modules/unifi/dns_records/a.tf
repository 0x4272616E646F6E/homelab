resource "unifi_dns_record" "unifi-private" {
  name        = "10.0.0.1"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "unifi.hosted.fail"
}

resource "unifi_dns_record" "btc" {
  name        = "10.0.0.64"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "btc.hosted.fail"
}

resource "unifi_dns_record" "haproxy" {
  name        = "10.0.0.247"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "haproxy.hosted.fail"
}

resource "unifi_dns_record" "nginx" {
  name        = "10.0.0.248"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "nginx.hosted.fail"
}

resource "unifi_dns_record" "traefik" {
  name        = "10.0.0.249"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "traefik.hosted.fail"
}

resource "unifi_dns_record" "talos" {
  name        = "10.0.0.250"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "talos.hosted.fail"
}

resource "unifi_dns_record" "pbs" {
  name        = "10.0.0.251"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "pbs.hosted.fail"
}

resource "unifi_dns_record" "pve" {
  name        = "10.0.0.252"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "pve.hosted.fail"
}

resource "unifi_dns_record" "bmc" {
  name        = "10.0.0.253"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "bmc.hosted.fail"
}

resource "unifi_dns_record" "nas" {
  name        = "10.0.0.254"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "nas.hosted.fail"
}

resource "unifi_dns_record" "unifi-personal" {
  name        = "10.0.1.1"
  enabled     = true
  port        = 0
  priority    = 10
  record_type = "A"
  ttl         = 300
  value       = "unifi.hosted.fail"
}
