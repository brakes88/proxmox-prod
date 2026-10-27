resource "proxmox_download_file" "debian_cloud" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node

  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"

  file_name = "debian-13-genericcloud-amd64.qcow2"
  overwrite = false
}

resource "proxmox_virtual_environment_vm" "debian_template" {
  name      = "debian-13-template"
  node_name = var.proxmox_node
  vm_id     = 9000

  description = "Template Debian 13 Cloud-Init gestito con Terraform"

  template = true
  started  = false
  on_boot  = false

  bios = "seabios"

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.debian_cloud.id
    interface    = "scsi0"
    size         = 20
    discard      = "on"
    iothread     = true
  }

  boot_order = ["scsi0"]

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "debian"
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = false
  }

  lifecycle {
    prevent_destroy = true
  }
}