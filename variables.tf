variable "proxmox_node" {
  description = "Nome del nodo Proxmox"
  type        = string
}

variable "ssh_public_key" {
  description = "Chiave pubblica SSH per le nuove VM Linux"
  type        = string
  default     = ""
}