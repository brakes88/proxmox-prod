resource "proxmox_virtual_environment_vm" "Satisfactory" {
  name      = "Satisfactory"
  node_name = var.proxmox_node
  vm_id     = 100

  started = true

  reboot_after_update = false

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

