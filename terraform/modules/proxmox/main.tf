resource "proxmox_vm_qemu" "talos" {
  name        = "talos"
  vmid        = 2250
  target_node = "pve"
  protection  = true
  onboot      = true
  startup     = "order=2,up=30"
  agent       = 1
  tags        = "linux"

  # Hardware
  machine  = "q35"
  cpu_type = "host"
  sockets  = 1
  cores    = 16
  memory   = 131072
  numa     = false
  tablet   = false
  hotplug  = "0"
  scsihw   = "virtio-scsi-single"
  os_type  = "other"

  # Boot disk (200G)
  disks {
    scsi {
      scsi0 {
        disk {
          storage    = "zfs"
          size       = "200G"
          discard    = true
          iothread   = true
          emulatessd = true
          cache      = "none"
          aio        = "native"
        }
      }
      scsi1 {
        disk {
          storage    = "zfs"
          size       = "40000G"
          discard    = true
          iothread   = true
          emulatessd = true
          cache      = "none"
          aio        = "native"
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "zfs"
        }
      }
    }
  }

  boot = "order=scsi0"

  # Network
  network {
    id       = 0
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
    queues   = 16
    macaddr  = "BC:24:11:61:5B:80"
  }

  # Cloud-init
  cicustom   = "user=local-pve:snippets/controlplane.yaml"
  ipconfig0  = "ip=10.0.0.250/24,gw=10.0.0.1"
  nameserver = "10.0.0.1"
  searchdomain = "hosted.fail"

  # PCI passthrough
  hostpci {
    host   = "0000:01:00"
    pcie   = true
  }
  hostpci {
    host   = "0000:0e:00"
    pcie   = true
  }
  hostpci {
    host   = "0000:03:00"
    pcie   = true
    rombar = false
  }
  hostpci {
    host   = "0000:0f:00"
    pcie   = true
    rombar = false
  }

  lifecycle {
    ignore_changes = [
      qemu_os,
    ]
  }
}

resource "proxmox_vm_qemu" "pbs" {
  name        = "pbs"
  vmid        = 2251
  target_node = "pve"
  protection  = true
  onboot      = true
  startup     = "order=1,up=30"
  agent       = 1
  tags        = "linux"

  # Hardware
  machine  = "q35"
  cpu_type = "host"
  sockets  = 1
  cores    = 4
  memory   = 8192
  numa     = false
  tablet   = false
  scsihw   = "virtio-scsi-single"
  os_type  = "l26"

  # Boot disk (32G)
  disks {
    scsi {
      scsi0 {
        disk {
          storage    = "zfs"
          size       = "32G"
          discard    = true
          iothread   = true
          emulatessd = true
          aio        = "native"
        }
      }
    }
  }

  boot = "order=scsi0"

  # Network
  network {
    id       = 0
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
    macaddr  = "BC:24:11:47:DD:28"
  }

  # PCI passthrough
  hostpci {
    host   = "0000:10:00.0"
    pcie   = true
    rombar = false
  }

  lifecycle {
    ignore_changes = [
      qemu_os,
    ]
  }
}
