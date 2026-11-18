terraform {
  required_version = ">= 1.11.4, < 2.0.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.78.0"
    }
  }
}
