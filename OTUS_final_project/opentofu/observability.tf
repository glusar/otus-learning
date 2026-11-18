# Параметры ВМ observability. Размеры дисков указаны в ГиБ, память — в МиБ.
resource "proxmox_virtual_environment_vm" "observability" {
  name      = "otus-observability"
  node_name = "pve"
  vm_id     = 124
  pool_id   = "otus-nextcloud"
  tags      = ["otus-nextcloud"]

  started             = true
  on_boot             = true
  reboot_after_update = false
  scsi_hardware       = "virtio-scsi-pci"
  boot_order          = ["scsi0"]

  clone {
    vm_id        = var.template_id
    full         = true
    datastore_id = "kingston"
  }

  lifecycle {
    # A new template applies to future clones.
    ignore_changes = [clone[0].vm_id]
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
    floating  = 0
  }

  agent {
    enabled = true
    timeout = "5m"
  }

  disk {
    datastore_id = "kingston"
    interface    = "scsi0"
    file_format  = "raw"
    size         = 48
  }

  # Порядок network_device соответствует порядку ip_config ниже.
  network_device {
    bridge = "vmbr2"
    model  = "virtio"
  }

  initialization {
    datastore_id = "kingston"
    interface    = "ide2"

    user_account {
      username = "ansible"
      keys     = [local.ssh_public_key]
    }

    dns {
      servers = ["192.168.1.111"]
    }

    ip_config {
      ipv4 {
        address = "10.20.0.20/24"
        gateway = "10.20.0.10"
      }
    }
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }
}
