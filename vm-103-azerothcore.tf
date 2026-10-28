# VM 103: AzerothCore — nodo proxmox
# Configurazione ricostruita da qm config e terraform state show del 27/10/2026.
# Questa VM e gia presente e importata nello state: NON importarla di nuovo.
# MODALITA GESTITA: hardware e opzioni Proxmox sotto Terraform, salvo esclusioni mirate.
# NON eseguire apply prima di avere controllato un plan completo con ZERO differenze.
# Eseguire il backup delle VM e dello state prima di interventi su disco/hardware.
# QEMU creazione: 11.0.3; ctime=1786460518
# VM Generation ID (solo riferimento, non gestito qui): 79b6e230-1ba6-41ed-a4b9-4bc3f089ab80
resource "proxmox_virtual_environment_vm" "AzerothCore" {
  # Identita VM (indirizzo Terraform invariato rispetto a existing.tf)
  name      = "AzerothCore"
  node_name = var.proxmox_node
  vm_id     = 103

  # Stato rilevato al momento della lettura e avvio automatico su Proxmox
  started  = false
  on_boot  = false
  template = false

  # Firmware, controller e boot
  bios          = "seabios"
  boot_order    = ["scsi0", "ide2", "net0"]
  scsi_hardware = "virtio-scsi-single"

  # Processore
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
    numa    = false
  }

  # Memoria in MB (floating=0 disabilita ballooning)
  memory {
    dedicated = 16000
    floating  = 0
  }

  # Disco esistente: dichiarare i parametri, non creare/importare un altro disco
  # Volume attuale: local-lvm:vm-103-disk-0 (da qm config e dallo state)
  # path_in_datastore e sperimentale: qui non viene impostato per evitare
  # di modificare la semantica di collegamento del disco esistente.
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 80
    file_format  = "raw"
    iothread     = true
    discard      = "ignore"
    ssd          = false
    backup       = true
    replicate    = true
    aio          = "io_uring"
    cache        = "none"
  }

  # CD-ROM attuale (ide2)
  cdrom {
    interface = "ide2"
    file_id   = "local:iso/debian-13.6.0-amd64-netinst.iso"
  }

  # Interfaccia di rete net0 (MAC fisso gia presente in Proxmox)
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "BC:24:11:E5:10:6D"
    firewall    = true
  }

  # QEMU guest agent e sistema operativo
  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  # Identificativo SMBIOS gia esistente
  smbios {
    uuid = "94e1f961-8fda-4478-b482-17c8d7df240b"
  }

  # Evita riavvii automatici dopo le modifiche; alcune modifiche possono fallire
  # se richiedono arresto VM, finche non vengono effettuate in manutenzione.
  reboot_after_update = false

  lifecycle {
    prevent_destroy = true
    # Lo stato di accensione continua a essere controllato da Proxmox.
    ignore_changes = [
      started,
      # Il provider 0.118 non ha popolato questi blocchi nell'import precedente.
      # Non applicare differenze implicite a ISO/CD-ROM o identita SMBIOS.
      cdrom,
      smbios,
    ]
  }
}
