# Токен берётся из переменной окружения PROXMOX_VE_API_TOKEN.
provider "proxmox" {
  endpoint = "https://192.168.1.101:8006/"
  insecure = true
}
