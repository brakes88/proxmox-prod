provider "proxmox" {
  endpoint = "https://192.168.1.200:8006/"

  # Da usare soltanto se Proxmox ha
  # un certificato SSL autofirmato
  insecure = true
}

data "proxmox_version" "server" {}

output "proxmox_version" {
  value = data.proxmox_version.server.version
}