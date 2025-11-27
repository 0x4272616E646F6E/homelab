# Address Groups
resource "unifi_firewall_group" "bastion_hosts" {
  name = "bastion_hosts"
  type = "address-group"
  members = ["10.0.1.124", "10.0.1.125", "10.0.1.126"]
}

resource "unifi_firewall_group" "rfc1918" {
  name = "rfc1918"
  type = "address-group"
  members = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

resource "unifi_firewall_group" "server_hosts" {
  name = "server_hosts"
  type = "address-group"
  members = ["10.0.0.247", "10.0.0.248", "10.0.0.249"]
}

# Port Groups
resource "unifi_firewall_group" "dns_ports" {
  name = "dns_ports"
  type = "port-group"
  members = ["53", "443", "784", "853"]
}

resource "unifi_firewall_group" "ntp_ports" {
  name = "ntp_ports"
  type = "port-group"
  members = ["123"]
}

resource "unifi_firewall_group" "unifi_management_ports" {
  name = "unifi_management_ports"
  type = "port-group"
  members = ["22", "80", "443"]
}

resource "unifi_firewall_group" "web_ports" {
  name = "web_ports"
  type = "port-group"
  members = ["80", "443"]
}
