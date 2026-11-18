output "management_addresses" {
  description = "Адреса управления ВМ для подключения Ansible"
  value = {
    proxy         = proxmox_virtual_environment_vm.proxy.initialization[0].ip_config[0].ipv4[0].address
    backend1      = proxmox_virtual_environment_vm.backend1.initialization[0].ip_config[0].ipv4[0].address
    backend2      = proxmox_virtual_environment_vm.backend2.initialization[0].ip_config[0].ipv4[0].address
    observability = proxmox_virtual_environment_vm.observability.initialization[0].ip_config[0].ipv4[0].address
  }
}
