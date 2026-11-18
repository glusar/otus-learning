variable "template_id" {
  description = "VMID вручную подготовленного шаблона Ubuntu"
  type        = number
  default     = 9001
}

locals {
  ssh_public_key = trimspace(file("${path.module}/../.secrets/ssh/otus_nextcloud_ed25519.pub"))
}
